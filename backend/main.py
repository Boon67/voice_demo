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

from models import SimulateRequest, SearchRequest, CallStatus, PlayRequest
import snowflake_ops as sf
import config
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
DEMO_RECORDINGS = {
    "demo_call": {"file": os.path.join(ASSETS_DIR, "demo_call.mp3"), "label": "Headphones Defect (Diana Prince)"},
    "demo_call_2": {"file": os.path.join(ASSETS_DIR, "demo_call_2.mp3"), "label": "Running Shoes Defect (Emily Rodriguez)"},
}
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
    global current_call, recorder, playback_task_running
    if recorder and recorder.is_recording:
        recorder.stop()
        recorder = None
    current_call.is_recording = False
    playback_task_running = False
    await broadcast({"type": "call_ended", "call_id": current_call.call_id})
    return {"status": "stopped"}


@app.post("/api/reset")
async def reset_app():
    global current_call, recorder, playback_task_running, _last_enrichment_len
    if recorder and recorder.is_recording:
        recorder.stop()
        recorder = None
    playback_task_running = False
    _last_enrichment_len = 0
    current_call = CallStatus()
    loop = asyncio.get_event_loop()
    success = await loop.run_in_executor(None, sf.reset_runtime_data)
    await broadcast({"type": "app_reset"})
    return {"status": "ok" if success else "partial", "reset": success}


@app.get("/api/config")
async def get_config():
    return config.get_config()


@app.post("/api/config")
async def update_config(updates: dict):
    return config.update_config(updates)


@app.get("/api/calls/status")
async def call_status():
    return current_call.model_dump()


@app.get("/api/recordings")
async def list_recordings():
    return [{"id": k, "label": v["label"]} for k, v in DEMO_RECORDINGS.items() if os.path.exists(v["file"])]


@app.post("/api/calls/play-recording")
async def play_recording(req: PlayRequest = PlayRequest()):
    global current_call, playback_task_running, _last_enrichment_len
    if playback_task_running:
        return {"error": "Playback already in progress"}

    recording = DEMO_RECORDINGS.get(req.recording_id)
    if not recording or not os.path.exists(recording["file"]):
        return {"error": f"Recording '{req.recording_id}' not found"}

    audio_path = recording["file"]
    _last_enrichment_len = 0
    call_id = str(uuid.uuid4())[:8]
    case_id = 9999
    current_call = CallStatus(call_id=call_id, case_id=case_id, is_recording=True)
    await broadcast({"type": "call_started", "call_id": call_id, "case_id": case_id})

    loop = asyncio.get_event_loop()
    duration = await loop.run_in_executor(None, get_audio_duration, audio_path)
    chunks = await loop.run_in_executor(None, split_audio_file, audio_path)

    await broadcast({
        "type": "playback_started",
        "call_id": call_id,
        "total_chunks": len(chunks),
        "duration_seconds": round(duration, 1),
    })

    asyncio.create_task(run_playback_pipeline(call_id, case_id, chunks, config.SEGMENT_SECONDS))
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

            async def process_with_semaphore(path, num, cid):
                async with CHUNK_SEMAPHORE:
                    await process_audio_segment(path, num, "playback", origin_call_id=cid)

            task = asyncio.create_task(process_with_semaphore(chunk_path, chunk_num, call_id))
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
        "speaker": "caller",
        "full_transcript": full_transcript,
    })

    await run_ai_pipeline(call_id, case_id, full_transcript)
    return {"status": "ok", "chunk": current_call.chunk_count}


async def process_audio_segment(path: str, chunk: int, stream_type: str, origin_call_id: str = None):
    call_id = origin_call_id or current_call.call_id
    case_id = current_call.case_id
    if not call_id:
        return

    loop = asyncio.get_event_loop()
    filename = os.path.basename(path)
    await loop.run_in_executor(None, sf.upload_audio_to_stage, path, filename)

    if current_call.call_id != call_id:
        return

    result = await loop.run_in_executor(None, sf.transcribe_audio, filename)
    if not result or not result.get("text"):
        return

    if current_call.call_id != call_id:
        return

    text = result["text"]
    duration = result.get("audio_duration", 0)
    await loop.run_in_executor(None, sf.insert_transcript, case_id, call_id, chunk, stream_type, text, duration)

    full_transcript = await loop.run_in_executor(None, sf.get_full_transcript, call_id)
    if current_call.call_id != call_id:
        return
    current_call.full_transcript = full_transcript
    current_call.chunk_count = chunk

    segments = await loop.run_in_executor(None, sf.diarize_chunk, text)
    if current_call.call_id != call_id:
        return
    for seg_idx, seg in enumerate(segments):
        await broadcast({
            "type": "transcript_update",
            "call_id": call_id,
            "chunk": f"{chunk}.{seg_idx}",
            "text": seg["text"],
            "speaker": seg["speaker"],
            "full_transcript": full_transcript,
        })

    if current_call.call_id == call_id:
        asyncio.create_task(maybe_run_enrichment(call_id, case_id, full_transcript))

    try:
        os.remove(path)
    except Exception:
        pass


_last_enrichment_len = 0


async def maybe_run_enrichment(call_id: str, case_id: int, full_transcript: str):
    global _last_enrichment_len
    if current_call.call_id != call_id:
        return
    transcript_len = len(full_transcript.strip())
    if transcript_len - _last_enrichment_len >= config.ENRICHMENT_MIN_CHARS or not current_call.is_recording:
        _last_enrichment_len = transcript_len
        await run_ai_pipeline(call_id, case_id, full_transcript)


async def run_ai_pipeline(call_id: str, case_id: int, full_transcript: str):
    if current_call.call_id != call_id:
        return
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
