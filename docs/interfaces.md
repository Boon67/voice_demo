# Call Center AI Demo — Interfaces

## REST API Endpoints

Base URL: `http://localhost:8080`

### Health & Configuration

| Method | Path | Description | Request | Response |
|--------|------|-------------|---------|----------|
| `GET` | `/api/health` | System health check | — | `{"backend": true, "snowflake": true, "audio": false, "call_active": false}` |
| `GET` | `/api/config` | Get current configuration | — | `{"segment_seconds": 15, "diarization_model": "llama3.1-8b", ...}` |
| `POST` | `/api/config` | Update configuration at runtime | JSON body with config keys | Updated config object |
| `GET` | `/api/recordings` | List available demo recordings | — | `[{"id": "demo_call", "label": "Headphones Defect (Diana Prince)"}, ...]` |

### Call Management

| Method | Path | Description | Request | Response |
|--------|------|-------------|---------|----------|
| `POST` | `/api/calls/play-recording` | Play a pre-recorded demo call | `{"recording_id": "demo_call"}` | `{"call_id": "abc123", "total_chunks": 9, "duration_seconds": 135.8}` |
| `POST` | `/api/calls/start` | Start live audio recording | — | `{"call_id": "...", "case_id": ...}` |
| `POST` | `/api/calls/stop` | Stop current recording/playback | — | `{"status": "ok"}` |
| `GET` | `/api/calls/status` | Get current call state | — | `{"call_id": "...", "is_recording": true, "chunk_count": 5}` |
| `POST` | `/api/calls/simulate` | Send text directly into AI pipeline | `{"text": "...", "call_id": "..."}` | `{"status": "ok"}` |
| `POST` | `/api/reset` | Reset all runtime data | — | `{"status": "ok", "reset": true}` |

### Customer Search

| Method | Path | Description | Request | Response |
|--------|------|-------------|---------|----------|
| `POST` | `/api/customers/search` | Search customers by name/phone/email | `{"query": "Diana"}` | Array of customer objects |

## WebSocket Interface

Endpoint: `ws://localhost:8080/ws`

### Connection Lifecycle
1. Client connects → server adds to `active_connections` set
2. Server broadcasts JSON messages to all connected clients
3. Client can send `{"type": "ping"}` → server responds `{"type": "pong"}`
4. On disconnect → server removes from set, client auto-reconnects after 3s

### Message Types (Server → Client)

| Type | When Sent | Key Fields |
|------|-----------|------------|
| `call_started` | New call begins | `call_id` |
| `transcript_update` | Each diarized segment | `call_id`, `text`, `speaker` ("agent"/"caller"), `chunk` (e.g., "3.1") |
| `extraction_update` | AI_EXTRACT completes | `call_id`, `extracted` (9-field object), `candidates` (array) |
| `customer_match` | Customer identified | `call_id`, `customer` (profile object), `orders` (array) |
| `product_match` | Products matched | `call_id`, `products` (array with match_score) |
| `similar_cases` | Similar cases found | `call_id`, `cases` (array with match_score), `count` |
| `recommendations` | Resolutions generated | `call_id`, `recommendations` (array with action, confidence, icon) |
| `playback_started` | Recording playback begins | `call_id`, `total_chunks` |
| `audio_progress` | Chunk processing progress | `chunk`, `total` |
| `playback_ended` | Playback complete | `call_id` |
| `call_ended` | Call session ends | `call_id` |
| `app_reset` | Runtime data cleared | — |

### Message Payloads

**transcript_update:**
```json
{
  "type": "transcript_update",
  "call_id": "bbc37edc",
  "text": "Hi, my name is Diana Prince.",
  "speaker": "caller",
  "chunk": "1.0"
}
```

**extraction_update:**
```json
{
  "type": "extraction_update",
  "call_id": "bbc37edc",
  "extracted": {
    "customer_name": "Diana Prince",
    "customer_phone": "8045551234",
    "customer_email": "diana.prince@gmail.com",
    "order_number": "ORD-2026-901",
    "product_name": "wireless noise-canceling headphones",
    "issue_description": "left ear keeps cutting out",
    "resolution_requested": "replacement",
    "shipping_address": null,
    "return_reason": "hardware defect"
  },
  "candidates": [
    {"field_name": "customer_name", "field_value": "Diana Prince"},
    {"field_name": "product_name", "field_value": "wireless noise-canceling headphones"}
  ]
}
```

**recommendations:**
```json
{
  "type": "recommendations",
  "call_id": "bbc37edc",
  "recommendations": [
    {
      "action": "Upgrade to Pro Version",
      "description": "Send the upgraded Pro version headphones at no extra cost.",
      "reasoning": "As a PLATINUM customer, Diana deserves the best experience.",
      "confidence": "high",
      "icon": "upgrade"
    },
    {
      "action": "Refund and Replacement",
      "description": "Full refund plus replacement pair of standard headphones.",
      "confidence": "medium",
      "icon": "replace"
    }
  ]
}
```

## Snowflake AI Function Interfaces

### AI_TRANSCRIBE

```sql
SELECT TO_VARCHAR(AI_TRANSCRIBE(TO_FILE('@CALL_CENTER.STG.TRANSCRIPTS', 'chunk_001.mp3')))
```

**Input:** Audio file on SSE-encrypted internal stage
**Output:** JSON with `text` field containing transcription

### AI_EXTRACT

```sql
SELECT TO_VARCHAR(AI_EXTRACT(
    text => '<transcript>',
    responseFormat => {
        'customer_name': 'What is the caller name?',
        'customer_phone': 'What is the phone number?',
        'customer_email': 'What is the email address?',
        'order_number': 'What order number was mentioned?',
        'product_name': 'What product is the caller calling about?',
        'issue_description': 'What is the issue?',
        'resolution_requested': 'What resolution is requested?',
        'shipping_address': 'What shipping address was mentioned?',
        'return_reason': 'What is the reason for return?'
    }
))
```

**Input:** Free-text transcript
**Output:** JSON object with 9 extracted fields

### AI_SIMILARITY

```sql
SELECT AI_SIMILARITY('<product_mention>', product_name) AS match_score
FROM PRODUCTS
WHERE AI_SIMILARITY('<product_mention>', product_name) > 0.3
```

**Input:** Two text strings to compare
**Output:** Float 0.0–1.0 (cosine similarity)

### AI_COMPLETE (Structured JSON)

```sql
SELECT TO_VARCHAR(AI_COMPLETE(
    model => 'llama3.1-8b',
    prompt => '<context and instructions>',
    response_format => {
        'type': 'json',
        'schema': {
            'type': 'object',
            'properties': { ... },
            'required': [...]
        }
    }
))
```

**Input:** Prompt text + JSON schema for output structure
**Output:** Structured JSON matching the provided schema

Used for:
- **Speaker diarization**: `{"segments": [{"speaker": "agent", "text": "..."}]}`
- **Resolution recommendations**: `{"recommendations": [{"action": "...", "confidence": "high", ...}]}`

## Database Interfaces

### Internal Stage

| Operation | SQL | Purpose |
|-----------|-----|---------|
| Upload | `PUT file://<path> @CALL_CENTER.STG.TRANSCRIPTS AUTO_COMPRESS=FALSE OVERWRITE=TRUE` | Upload audio chunk for transcription |
| Remove | `REMOVE @CALL_CENTER.STG.TRANSCRIPTS` | Clear all staged files on reset |

### Key Queries

| Operation | Table(s) | Join Pattern |
|-----------|----------|-------------|
| Customer search | CUSTOMERS | LIKE on name, phone, email |
| Order history | ORDERS → ORDER_ITEMS → PRODUCTS | JOIN chain by customer_id → order_id → product_id |
| Product matching | ORDER_ITEMS → PRODUCTS → ORDERS | AI_SIMILARITY on product name, filtered by customer_id |
| Case matching | CASES | AI_SIMILARITY on issue_description |
| Transcript assembly | CALL_TRANSCRIPTS | WHERE call_id, ORDER BY chunk_number |
