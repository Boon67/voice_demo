import os
import uuid
import json
import asyncio
import logging
import tempfile
from typing import Set
from contextlib import asynccontextmanager

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from models import SimulateRequest, SearchRequest, CallStatus
import snowflake_ops as sf
from audio import AudioRecorder, AUDIO_AVAILABLE
from audio_player import split_audio_file, cleanup_chunks, get_audio_duration

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

active_connections: Set[WebSocket] = set()
current_call = CallStatus()
recorder: AudioRecorder | None = None
TEMP_DIR = os.path.join(tempfile.gettempdir(), "call_center_audio")
os.makedirs(TEMP_DIR, exist_ok=True)

ASSETS_DIR = os.path.join(os.path.dirname(__file__), "assets")
DEMO_AUDIO = os.path.join(ASSETS_DIR, "demo_call.mp3")
playback_task_running = False
CHUNK_SEMAPHORE = asyncio.Semaphore(3)


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Call Center AI Demo starting...")
    yield
    logger.info("Shutting down...")


app = FastAPI(title="Call Center AI Demo", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if os.path.isdir(ASSETS_DIR):
    app.mount("/api/audio", StaticFiles(directory=ASSETS_DIR), name="audio")


async def broadcast(message: dict):
    dead = set()
    for ws in active_connections:
        try:
            await ws.send_json(message)
        except Exception:
            dead.add(ws)
    active_connections.difference_update(dead)


@app.get("/api/health")
async def health():
    sf_ok = sf.test_connection()
    return {
        "backend": True,
        "snowflake": sf_ok,
        "audio": AUDIO_AVAILABLE,
        "call_active": current_call.is_recording,
    }


@app.post("/api/customers/search")
async def search_customers(req: SearchRequest):
    customers = sf.search_customers(req.query)
    results = []
    for c in customers:
        orders = sf.get_customer_orders(c["customer_id"])
        results.append({"customer": c, "orders": orders})
    return {"results": results}


@app.post("/api/calls/start")
async def start_call():
    global current_call, recorder, _last_enrichment_len
    _last_enrichment_len = 0
    call_id = str(uuid.uuid4())[:8]
    case_id = 9999
    current_call = CallStatus(call_id=call_id, case_id=case_id, is_recording=True)

    if AUDIO_AVAILABLE:
        def on_segment(path, chunk, stream_type):
            asyncio.get_event_loop().call_soon_threadsafe(
                asyncio.create_task,
                process_audio_segment(path, chunk, stream_type)
            )
        recorder = AudioRecorder(case_id, call_id, TEMP_DIR, on_segment=on_segment)
        recorder.start()

    await broadcast({"type": "call_started", "call_id": call_id, "case_id": case_id})
    return {"call_id": call_id, "case_id": case_id, "audio_enabled": AUDIO_AVAILABLE}


@app.post("/api/calls/stop")
async def stop_call():
    global current_call, recorder
    if recorder and recorder.is_recording:
        recorder.stop()
        recorder = None
    current_call.is_recording = False
    await broadcast({"type": "call_ended", "call_id": current_call.call_id})
    return {"status": "stopped"}


@app.get("/api/calls/status")
async def call_status():
    return current_call.model_dump()


@app.post("/api/calls/play-recording")
async def play_recording():
    global current_call, playback_task_running, _last_enrichment_len
    if playback_task_running:
        return {"error": "Playback already in progress"}
    if not os.path.exists(DEMO_AUDIO):
        return {"error": "Demo audio file not found at backend/assets/demo_call.mp3"}

    _last_enrichment_len = 0
    call_id = str(uuid.uuid4())[:8]
    case_id = 9999
    current_call = CallStatus(call_id=call_id, case_id=case_id, is_recording=True)
    await broadcast({"type": "call_started", "call_id": call_id, "case_id": case_id})

    loop = asyncio.get_event_loop()
    duration = await loop.run_in_executor(None, get_audio_duration, DEMO_AUDIO)
    chunks = await loop.run_in_executor(None, split_audio_file, DEMO_AUDIO)

    await broadcast({
        "type": "playback_started",
        "call_id": call_id,
        "total_chunks": len(chunks),
        "duration_seconds": round(duration, 1),
    })

    asyncio.create_task(run_playback_pipeline(call_id, case_id, chunks, 5))
    return {
        "call_id": call_id,
        "total_chunks": len(chunks),
        "duration_seconds": round(duration, 1),
    }


async def run_playback_pipeline(call_id: str, case_id: int, chunks, segment_seconds: int):
    global playback_task_running
    playback_task_running = True
    tasks = []
    try:
        for i, chunk_path in enumerate(chunks):
            if not current_call.is_recording:
                break

            chunk_num = i + 1
            await broadcast({
                "type": "audio_progress",
                "call_id": call_id,
                "chunk": chunk_num,
                "total": len(chunks),
                "elapsed": chunk_num * segment_seconds,
            })

            async def process_with_semaphore(path, num):
                async with CHUNK_SEMAPHORE:
                    await process_audio_segment(path, num, "playback")

            task = asyncio.create_task(process_with_semaphore(chunk_path, chunk_num))
            tasks.append(task)

            if i < len(chunks) - 1 and current_call.is_recording:
                await asyncio.sleep(segment_seconds)

        await asyncio.gather(*tasks, return_exceptions=True)
    finally:
        playback_task_running = False
        cleanup_chunks(chunks)
        current_call.is_recording = False
        await broadcast({"type": "playback_ended", "call_id": call_id})


@app.post("/api/calls/simulate")
async def simulate_call(req: SimulateRequest):
    global current_call
    call_id = req.call_id or current_call.call_id or str(uuid.uuid4())[:8]
    case_id = current_call.case_id or 9999

    if not current_call.is_recording:
        current_call = CallStatus(call_id=call_id, case_id=case_id, is_recording=True)
        await broadcast({"type": "call_started", "call_id": call_id, "case_id": case_id})

    current_call.chunk_count += 1
    sf.insert_transcript(case_id, call_id, current_call.chunk_count, "simulated", req.text, 0)

    full_transcript = sf.get_full_transcript(call_id)
    current_call.full_transcript = full_transcript

    await broadcast({
        "type": "transcript_update",
        "call_id": call_id,
        "chunk": current_call.chunk_count,
        "text": req.text,
        "full_transcript": full_transcript,
    })

    await run_ai_pipeline(call_id, case_id, full_transcript)
    return {"status": "ok", "chunk": current_call.chunk_count}


async def process_audio_segment(path: str, chunk: int, stream_type: str):
    call_id = current_call.call_id
    case_id = current_call.case_id
    if not call_id:
        return

    loop = asyncio.get_event_loop()
    filename = os.path.basename(path)
    await loop.run_in_executor(None, sf.upload_audio_to_stage, path, filename)

    result = await loop.run_in_executor(None, sf.transcribe_audio, filename)
    if not result or not result.get("text"):
        return

    text = result["text"]
    duration = result.get("audio_duration", 0)
    await loop.run_in_executor(None, sf.insert_transcript, case_id, call_id, chunk, stream_type, text, duration)

    full_transcript = await loop.run_in_executor(None, sf.get_full_transcript, call_id)
    current_call.full_transcript = full_transcript
    current_call.chunk_count = chunk

    await broadcast({
        "type": "transcript_update",
        "call_id": call_id,
        "chunk": chunk,
        "text": text,
        "full_transcript": full_transcript,
    })

    asyncio.create_task(maybe_run_enrichment(call_id, case_id, full_transcript))

    try:
        os.remove(path)
    except Exception:
        pass


_last_enrichment_len = 0


async def maybe_run_enrichment(call_id: str, case_id: int, full_transcript: str):
    global _last_enrichment_len
    transcript_len = len(full_transcript.strip())
    if transcript_len - _last_enrichment_len >= 100 or not current_call.is_recording:
        _last_enrichment_len = transcript_len
        await run_ai_pipeline(call_id, case_id, full_transcript)


async def run_ai_pipeline(call_id: str, case_id: int, full_transcript: str):
    if not full_transcript or len(full_transcript.strip()) < 20:
        return

    loop = asyncio.get_event_loop()
    extracted = await loop.run_in_executor(None, sf.extract_call_info, full_transcript)

    if extracted:
        await loop.run_in_executor(None, sf.save_candidate_values, case_id, call_id, extracted)
        candidates = await loop.run_in_executor(None, sf.get_candidate_values, call_id)
        await broadcast({
            "type": "extraction_update",
            "call_id": call_id,
            "extracted": extracted,
            "candidates": candidates,
        })

    customer_name = extracted.get("customer_name")
    product_mention = extracted.get("product_name")
    issue_desc = extracted.get("issue_description")

    matched_customer = None
    if customer_name and customer_name.lower() not in ("none", "null", "n/a", ""):
        customers = await loop.run_in_executor(None, sf.search_customers, customer_name)
        if customers:
            matched_customer = customers[0]
            orders = await loop.run_in_executor(None, sf.get_customer_orders, matched_customer["customer_id"])
            await broadcast({
                "type": "customer_match",
                "call_id": call_id,
                "customer": matched_customer,
                "orders": orders,
            })

    if product_mention and matched_customer and product_mention.lower() not in ("none", "null", "n/a", ""):
        products = await loop.run_in_executor(None, sf.match_products, matched_customer["customer_id"], product_mention)
        if products:
            await broadcast({
                "type": "product_match",
                "call_id": call_id,
                "products": products,
            })

    if issue_desc and issue_desc.lower() not in ("none", "null", "n/a", ""):
        similar = await loop.run_in_executor(None, sf.find_similar_cases, issue_desc)
        if similar:
            await broadcast({
                "type": "similar_cases",
                "call_id": call_id,
                "cases": similar,
                "count": len(similar),
            })


@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await ws.accept()
    active_connections.add(ws)
    logger.info(f"WebSocket connected. Total: {len(active_connections)}")
    try:
        while True:
            data = await ws.receive_text()
            msg = json.loads(data)
            if msg.get("type") == "ping":
                await ws.send_json({"type": "pong"})
    except WebSocketDisconnect:
        pass
    finally:
        active_connections.discard(ws)
        logger.info(f"WebSocket disconnected. Total: {len(active_connections)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
