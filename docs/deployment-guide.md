# Call Center AI Demo — Deployment Guide

## Prerequisites

| Requirement | Version | Purpose |
|------------|---------|---------|
| Snowflake Account | — | With Cortex AI function access (AI_TRANSCRIBE, AI_EXTRACT, AI_SIMILARITY, AI_COMPLETE) |
| Python | 3.10+ | Backend runtime |
| Node.js | 18+ | Frontend build and dev server |
| npm | 9+ | Frontend package manager |
| ffmpeg | 4+ | Audio segmentation for demo playback |
| Snowflake CLI | — | Optional: for running SQL scripts via `snowsql` |

### Install ffmpeg

```bash
# macOS
brew install ffmpeg

# Ubuntu/Debian
sudo apt-get install ffmpeg

# Verify
ffmpeg -version
```

### Snowflake Connection

Configure a named connection in `~/.snowflake/config.toml`:

```toml
[connections.MYCONNECTION]
account = "YOUR_ACCOUNT"
user = "YOUR_USER"
authenticator = "externalbrowser"  # or "snowflake" for password auth
role = "SYSADMIN"
warehouse = "COMPUTE_WH"
database = "CALL_CENTER"
```

## Step 1: Set Up Snowflake Database

Run the SQL scripts in order. Use Snowsight, SnowSQL, or any SQL client:

```bash
# Create database, schemas, stage, and all 7 hybrid tables
snowsql -c MYCONNECTION -f sql/01_setup.sql

# Populate demo data (8 customers, 10 products, 11 orders, 14 items, 7 cases)
snowsql -c MYCONNECTION -f sql/02_seed_data.sql
```

**Verify:**
```sql
USE DATABASE CALL_CENTER;
SELECT 'CUSTOMERS' AS TBL, COUNT(*) AS CNT FROM CUSTOMERS
UNION ALL SELECT 'PRODUCTS', COUNT(*) FROM PRODUCTS
UNION ALL SELECT 'ORDERS', COUNT(*) FROM ORDERS
UNION ALL SELECT 'ORDER_ITEMS', COUNT(*) FROM ORDER_ITEMS
UNION ALL SELECT 'CASES', COUNT(*) FROM CASES;
```

Expected: CUSTOMERS=8, PRODUCTS=10, ORDERS=11, ORDER_ITEMS=14, CASES=7.

## Step 2: Set Up Backend

```bash
cd backend

# Create virtual environment
python3 -m venv .venv
source .venv/bin/activate    # macOS/Linux
# .venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt
```

**Note:** PyAudio may fail on macOS without PortAudio. This is optional — the app works without it (demo playback mode doesn't need live audio). To install:
```bash
brew install portaudio       # macOS
pip install pyaudio
```

## Step 3: Set Up Frontend

```bash
cd frontend
npm install
```

## Step 4: Start the Application

### Terminal 1 — Backend

```bash
cd backend
source .venv/bin/activate
SNOWFLAKE_CONNECTION_NAME=MYCONNECTION python main.py
```

Expected output:
```
INFO:     Uvicorn running on http://0.0.0.0:8080
```

Verify:
```bash
curl http://localhost:8080/api/health
# {"backend":true,"snowflake":true,"audio":false,"call_active":false}
```

### Terminal 2 — Frontend

```bash
cd frontend
DISABLE_ESLINT_PLUGIN=true npm start
```

Open **http://localhost:3000** in your browser.

## Step 5: Verify

1. **Header status dots** should show green for API, Snowflake, and WS
2. Select a demo recording from the dropdown
3. Click **Play** — audio processes through the pipeline
4. Cards should progressively appear: Call Summary → Customer → Products → Similar Cases → Recommendations

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SNOWFLAKE_CONNECTION_NAME` | Yes | `default` | Connection name from `~/.snowflake/config.toml` |
| `DISABLE_ESLINT_PLUGIN` | No | — | Set to `true` to suppress ESLint warnings in React dev server |

### Runtime Configuration

Adjustable via the collapsible config panel in the sidebar, or `POST /api/config`:

| Setting | Default | Description |
|---------|---------|-------------|
| `segment_seconds` | 15 | Audio chunk duration in seconds |
| `diarization_model` | `llama3.1-8b` | Snowflake model for speaker diarization |
| `similarity_threshold_product` | 0.3 | Minimum AI_SIMILARITY score for product matching |
| `similarity_threshold_case` | 0.4 | Minimum AI_SIMILARITY score for case matching |
| `enrichment_min_chars` | 100 | Minimum new characters before re-running enrichment |

## Maintenance

### Between Demo Runs

```bash
snowsql -c MYCONNECTION -f sql/04_reset_runtime.sql
```

Or click **Reset** in the sidebar, or:
```bash
curl -X POST http://localhost:8080/api/reset
```

### Full Teardown

```bash
snowsql -c MYCONNECTION -f sql/03_teardown.sql
```

### Rebuild From Scratch

```bash
snowsql -c MYCONNECTION -f sql/01_setup.sql
snowsql -c MYCONNECTION -f sql/02_seed_data.sql
```

## Adding New Demo Recordings

1. Place MP3 file in `backend/assets/` (e.g., `new_call.mp3`)
2. Add entry to `DEMO_RECORDINGS` dict in `backend/main.py`:
   ```python
   DEMO_RECORDINGS = {
       "demo_call": {"path": "assets/demo_call.mp3", "label": "Headphones Defect (Diana Prince)"},
       "new_call": {"path": "assets/new_call.mp3", "label": "Your New Scenario"},
   }
   ```
3. Restart backend

### Generating TTS Audio

Use the included script on macOS:
```bash
cd backend/scripts
chmod +x generate_call.sh
./generate_call.sh
```

Edit the script to change the conversation script, voices, and speech rate.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `snowflake: false` in health check | Verify `SNOWFLAKE_CONNECTION_NAME` matches a connection in `~/.snowflake/config.toml` |
| Port 3000 in use | `lsof -ti:3000 \| xargs kill` then restart frontend |
| Port 8080 in use | `lsof -ti:8080 \| xargs kill` then restart backend |
| PyAudio install fails | `brew install portaudio` first (macOS). Not required for demo playback. |
| AI functions return empty | Ensure Snowflake account has Cortex AI access. Stage must use `SNOWFLAKE_SSE` encryption. |
| WebSocket not connecting | Confirm backend running on 8080. Check browser console. |
| Slow AI responses | Normal: each pipeline run takes 15-30 seconds. AI functions process sequentially in Snowflake. |
| Play Recording does nothing | Verify ffmpeg installed: `ffmpeg -version`. Install: `brew install ffmpeg`. |
| Playback stalls | Check backend logs. Run `sql/04_reset_runtime.sql` and retry. |
| Center panel won't scroll | CSS Grid items need `min-height: 0`. Already applied in current CSS. |

## Project Structure

```
voice_demo/
├── sql/
│   ├── 01_setup.sql              # Database, schemas, stage, hybrid tables
│   ├── 02_seed_data.sql          # Demo data
│   ├── 03_teardown.sql           # Drop everything
│   └── 04_reset_runtime.sql      # Clear between demo runs
├── backend/
│   ├── main.py                   # FastAPI app + AI pipeline
│   ├── snowflake_ops.py          # All Snowflake operations
│   ├── audio_player.py           # ffmpeg audio splitting
│   ├── audio.py                  # PyAudio recorder (optional)
│   ├── config.py                 # Runtime configuration
│   ├── models.py                 # Pydantic models
│   ├── requirements.txt          # Python dependencies
│   ├── assets/                   # Demo MP3 recordings
│   └── scripts/                  # TTS generation script
├── frontend/
│   ├── src/
│   │   ├── App.jsx               # Main app + state management
│   │   ├── hooks/useWebSocket.js # WebSocket subscribe hook
│   │   ├── components/           # UI components
│   │   └── styles/App.css        # Full CSS
│   └── package.json
├── docs/                         # Project documentation
└── README.md
```
