# Call Center AI Demo — Workflow Documentation

## Primary Workflow: Demo Recording Playback

This is the main demo flow — a pre-recorded customer call is played through the full AI pipeline.

### Sequence

```
User clicks "Play" in sidebar
         │
         ▼
    POST /api/calls/play-recording {"recording_id": "demo_call"}
         │
         ▼
    Backend: generate call_id, case_id
    Backend: broadcast "call_started"
    Backend: split MP3 into 15s chunks via ffmpeg
         │
         ▼
    ┌─── FOR EACH CHUNK (sequential, with pacing) ───┐
    │                                                  │
    │  1. PUT chunk to @STG.TRANSCRIPTS                │
    │  2. AI_TRANSCRIBE → raw text                     │
    │  3. INSERT into CALL_TRANSCRIPTS                 │
    │  4. AI_COMPLETE (diarize) → speaker segments     │
    │  5. Broadcast "transcript_update" per segment    │
    │  6. GET full transcript so far                   │
    │  7. maybe_run_enrichment() (if 100+ new chars)   │
    │     └─► run_ai_pipeline()                        │
    │                                                  │
    │  broadcast "audio_progress" {chunk, total}       │
    └──────────────────────────────────────────────────┘
         │
         ▼
    broadcast "playback_ended"
```

### AI Enrichment Pipeline (run_ai_pipeline)

Triggered when sufficient new transcript text accumulates (100+ characters since last run):

```
Full transcript text
         │
         ▼
    AI_EXTRACT → 9 structured fields
         │
         ├─► save_candidate_values() → CALL_CANDIDATE_VALUES
         └─► broadcast "extraction_update"
         │
         ▼
    Is customer_name extracted?
         │
    YES  │  NO → skip
         ▼
    search_customers(name) → best match
    get_customer_orders(customer_id)
    broadcast "customer_match"
         │
         ▼
    Is product_name extracted AND customer matched?
         │
    YES  │  NO → skip
         ▼
    AI_SIMILARITY(product_mention vs order history)
    broadcast "product_match"
         │
         ▼
    Is issue_description extracted?
         │
    YES  │  NO → skip
         ▼
    AI_SIMILARITY(issue vs CASES.issue_description)
    broadcast "similar_cases"
         │
         ▼
    AI_COMPLETE → generate_recommendations()
      context: customer tier, issue, product, past resolutions, transcript
    broadcast "recommendations"
```

## WebSocket Event Flow

### Frontend Subscribe Pattern

```
App.jsx mounts
    │
    └─► useWebSocket().subscribe(handler)
              │
              ├── "call_started"      → reset all state
              ├── "transcript_update" → append message (dedup by chunk ID, sort)
              ├── "extraction_update" → setCandidates, setExtracted
              ├── "customer_match"    → setCustomer, setOrders, setCallerName
              ├── "product_match"     → setProducts
              ├── "similar_cases"     → setSimilarCases
              ├── "recommendations"   → setRecommendations
              ├── "playback_started"  → setIsPlaying, setPlaybackProgress
              ├── "audio_progress"    → setPlaybackProgress
              ├── "playback_ended"    → setIsPlaying(false)
              └── "app_reset"         → reset all state
```

### Message Deduplication

Transcript updates use sub-chunk IDs (e.g., `"3.0"`, `"3.1"`) for proper ordering:
- Main chunk number = audio segment index
- Sub-chunk number = diarization segment within that chunk
- Frontend deduplicates by checking `prev.some(m => m.chunk === chunkId)`
- Sorting: split on `.`, compare main then sub as numbers

### Bubble Merging

`TranscriptPanel` uses `useMemo` to merge consecutive same-speaker messages:
```
Input:  [{speaker: "agent", text: "Hi"}, {speaker: "agent", text: "How can I help?"}]
Output: [{speaker: "agent", texts: ["Hi", "How can I help?"]}]
```

## Audio Processing Pipeline

### Play Recording Mode

```
demo_call.mp3 (135.8s)
         │
    ffmpeg -i demo_call.mp3 -f segment -segment_time 15 -c copy chunk_%03d.mp3
         │
         ├── chunk_000.mp3 (0:00 - 0:15)
         ├── chunk_001.mp3 (0:15 - 0:30)
         ├── chunk_002.mp3 (0:30 - 0:45)
         │   ...
         └── chunk_008.mp3 (2:00 - 2:15)
         │
    Each chunk → PUT to stage → AI_TRANSCRIBE → diarize → broadcast
```

### Timing & Pacing

- Each chunk processed sequentially
- `asyncio.run_in_executor` wraps all blocking Snowflake calls
- Pipeline for one chunk: ~10-20 seconds (upload + transcribe + diarize)
- Enrichment pipeline: ~15-30 seconds (extract + match + similarity + recommendations)
- Enrichment throttled: only runs when 100+ new characters accumulated

## State Machine: Call Lifecycle

```
    ┌──────────┐
    │   IDLE   │ ◄──── POST /api/reset
    └────┬─────┘       broadcast "app_reset"
         │
    POST /api/calls/play-recording
         │
         ▼
    ┌──────────┐
    │ PLAYING  │ ──── broadcast "call_started"
    │          │      broadcast "playback_started"
    └────┬─────┘
         │
         ├── chunk processed → broadcast "audio_progress"
         ├── AI results → broadcast extraction/match/similar/recommendations
         │
         ├── POST /api/calls/stop ─────┐
         │                              │
         │   All chunks done            │
         │                              │
         ▼                              ▼
    ┌──────────┐                  ┌──────────┐
    │ COMPLETE │                  │ STOPPED  │
    │          │                  │          │
    └────┬─────┘                  └────┬─────┘
         │                              │
         └──────────┬───────────────────┘
                    │
               POST /api/reset
                    │
                    ▼
              ┌──────────┐
              │   IDLE   │
              └──────────┘
```

## Reset Flow

```
POST /api/reset
    │
    ├── Stop any active recording/playback
    ├── REMOVE @CALL_CENTER.STG.TRANSCRIPTS
    ├── TRUNCATE TABLE CALL_TRANSCRIPTS
    ├── TRUNCATE TABLE CALL_CANDIDATE_VALUES
    ├── Clear in-memory call state
    └── broadcast "app_reset" → UI resets all state
```
