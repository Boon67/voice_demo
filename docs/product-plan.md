# Call Center AI Demo — Product Plan

## Executive Summary

A real-time AI agent assist dashboard demonstrating Snowflake Cortex AI capabilities in a call center context. The system transcribes live conversations, extracts entities, identifies customers, matches products, surfaces similar cases, and recommends resolutions — all powered entirely by Snowflake AI functions.

## Requirements Register

| ID | Title | Description | Priority | Source |
|----|-------|-------------|----------|--------|
| REQ-001 | Real-time transcription | Transcribe call audio to text in real time as the conversation unfolds | Must-have | Core demo |
| REQ-002 | Speaker identification | Distinguish between agent and caller in the transcript | Must-have | Core demo |
| REQ-003 | Entity extraction | Extract structured data (name, phone, email, product, issue, order number) from transcript | Must-have | Core demo |
| REQ-004 | Customer identification | Automatically identify the caller from extracted information | Must-have | Core demo |
| REQ-005 | Order history lookup | Show the identified customer's order history | Must-have | Core demo |
| REQ-006 | Product matching | Match mentioned products against the customer's order history | Must-have | Core demo |
| REQ-007 | Similar case detection | Find historically similar support cases based on the issue description | Must-have | Core demo |
| REQ-008 | Resolution recommendations | Suggest resolution options based on customer profile, issue, and past outcomes | Must-have | Core demo |
| REQ-009 | Progressive real-time UI | Display AI results as they arrive, not after the call ends | Must-have | UX |
| REQ-010 | Demo playback mode | Play pre-recorded calls through the full pipeline for reliable presentations | Must-have | Demo reliability |
| REQ-011 | Live transcript panel | Show conversation as iMessage-style chat bubbles with speaker labels | Should-have | UX |
| REQ-012 | Customer loyalty awareness | Factor customer loyalty tier into recommendations and display | Should-have | Business logic |
| REQ-013 | Configurable thresholds | Allow runtime adjustment of AI model, similarity thresholds, and segment duration | Should-have | Flexibility |
| REQ-014 | Health monitoring | Show system connectivity status (API, Snowflake, WebSocket) | Should-have | Observability |
| REQ-015 | Multiple demo scenarios | Support different pre-recorded calls for varied demonstrations | Nice-to-have | Demo variety |
| REQ-016 | Live microphone recording | Record live audio from microphone for real call scenarios | Nice-to-have | Production path |
| REQ-017 | New instance deployment | Package the project so it can be deployed as a new instance on any Snowflake account | Must-have | Portability |

## Capability Map

| ID | Capability | Category | Requirement(s) |
|----|-----------|----------|-----------------|
| CAP-001 | Audio-to-text conversion | AI/Functional | REQ-001 |
| CAP-002 | Speaker diarization | AI/Functional | REQ-002 |
| CAP-003 | Structured entity extraction from text | AI/Functional | REQ-003 |
| CAP-004 | Customer search and matching | Data/Functional | REQ-004, REQ-012 |
| CAP-005 | Order and product history retrieval | Data/Functional | REQ-005 |
| CAP-006 | Semantic similarity matching | AI/Functional | REQ-006, REQ-007 |
| CAP-007 | LLM-powered recommendation generation | AI/Functional | REQ-008, REQ-012 |
| CAP-008 | Real-time bidirectional communication | Integration | REQ-009, REQ-011, REQ-014 |
| CAP-009 | Audio file segmentation and pacing | Functional | REQ-010, REQ-015 |
| CAP-010 | Runtime configuration management | Functional | REQ-013 |
| CAP-011 | Live audio capture | Functional | REQ-016 |
| CAP-012 | Scripted database provisioning | Infrastructure | REQ-017 |

## Feature Specification

| ID | Feature | Capability | Complexity | Dependencies |
|----|---------|-----------|------------|-------------|
| FEAT-001 | AI_TRANSCRIBE integration | CAP-001 | Medium | Stage setup, audio upload |
| FEAT-002 | AI_COMPLETE speaker diarization | CAP-002 | Medium | FEAT-001 |
| FEAT-003 | AI_EXTRACT 9-field extraction | CAP-003 | Low | FEAT-001 |
| FEAT-004 | Customer LIKE search | CAP-004 | Low | Database seed data |
| FEAT-005 | Order history with line items | CAP-005 | Low | FEAT-004 |
| FEAT-006 | AI_SIMILARITY product matching | CAP-006 | Medium | FEAT-003, FEAT-004 |
| FEAT-007 | AI_SIMILARITY case matching | CAP-006 | Medium | FEAT-003 |
| FEAT-008 | AI_COMPLETE resolution recommendations | CAP-007 | High | FEAT-003, FEAT-004, FEAT-007 |
| FEAT-009 | WebSocket subscribe pattern | CAP-008 | Medium | — |
| FEAT-010 | Progressive card rendering | CAP-008 | Medium | FEAT-009 |
| FEAT-011 | ffmpeg audio chunking | CAP-009 | Medium | ffmpeg installed |
| FEAT-012 | Demo recording management | CAP-009 | Low | FEAT-011 |
| FEAT-013 | Collapsible config panel | CAP-010 | Low | — |
| FEAT-014 | Live mic recording (PyAudio) | CAP-011 | High | PortAudio installed |
| FEAT-015 | SQL setup/seed/teardown/reset scripts | CAP-012 | Low | Snowflake account |
| FEAT-016 | 3-panel CSS Grid layout | CAP-008 | Medium | — |
| FEAT-017 | iMessage transcript bubbles | CAP-008 | Medium | FEAT-002 |
| FEAT-018 | Call timer and progress bar | CAP-008 | Low | FEAT-011 |
| FEAT-019 | Health status indicators | CAP-008 | Low | — |
| FEAT-020 | AnimatedCard entrance animation | CAP-008 | Low | FEAT-016 |

## Deliverables

| ID | Deliverable | Type | Feature(s) | Effort | Owner |
|----|------------|------|-----------|--------|-------|
| DEL-001 | `snowflake_ops.py` — Snowflake data access layer | Code | FEAT-001–008 | L | Backend |
| DEL-002 | `main.py` — FastAPI app + pipeline orchestration | Code | FEAT-009, FEAT-011, FEAT-012 | XL | Backend |
| DEL-003 | `audio_player.py` — ffmpeg audio splitting | Code | FEAT-011 | M | Backend |
| DEL-004 | `audio.py` — PyAudio recorder | Code | FEAT-014 | M | Backend |
| DEL-005 | `config.py` — Runtime configuration | Code | FEAT-013 | S | Backend |
| DEL-006 | `models.py` — Pydantic data models | Code | ALL | S | Backend |
| DEL-007 | `App.jsx` — Root component + state management | Code | FEAT-009, FEAT-010, FEAT-016 | L | Frontend |
| DEL-008 | UI Components (9 files) | Code | FEAT-010, FEAT-016–020 | L | Frontend |
| DEL-009 | `useWebSocket.js` — Subscribe hook | Code | FEAT-009 | M | Frontend |
| DEL-010 | `App.css` — Full application styles | Code | FEAT-016, FEAT-020 | L | Frontend |
| DEL-011 | `01_setup.sql` — Database schema | Infrastructure | FEAT-015 | M | Data |
| DEL-012 | `02_seed_data.sql` — Demo data | Infrastructure | FEAT-015 | M | Data |
| DEL-013 | `03_teardown.sql` + `04_reset_runtime.sql` | Infrastructure | FEAT-015 | S | Data |
| DEL-014 | `demo_call.mp3` + `demo_call_2.mp3` | Asset | FEAT-012 | S | Content |
| DEL-015 | `generate_call.sh` — TTS generation script | Code | FEAT-012 | S | Tooling |
| DEL-016 | `requirements.txt` + `package.json` | Config | ALL | S | DevOps |
| DEL-017 | Project documentation (`/docs`) | Documentation | REQ-017 | L | Docs |

## Traceability Matrix

| REQ | Capability | Feature(s) | Deliverable(s) | Priority | Status |
|-----|-----------|-----------|----------------|----------|--------|
| REQ-001 | CAP-001 | FEAT-001 | DEL-001, DEL-002 | Must | Done |
| REQ-002 | CAP-002 | FEAT-002 | DEL-001 | Must | Done |
| REQ-003 | CAP-003 | FEAT-003 | DEL-001 | Must | Done |
| REQ-004 | CAP-004 | FEAT-004 | DEL-001 | Must | Done |
| REQ-005 | CAP-005 | FEAT-005 | DEL-001 | Must | Done |
| REQ-006 | CAP-006 | FEAT-006 | DEL-001 | Must | Done |
| REQ-007 | CAP-006 | FEAT-007 | DEL-001 | Must | Done |
| REQ-008 | CAP-007 | FEAT-008 | DEL-001 | Must | Done |
| REQ-009 | CAP-008 | FEAT-009, FEAT-010 | DEL-007, DEL-009 | Must | Done |
| REQ-010 | CAP-009 | FEAT-011, FEAT-012 | DEL-002, DEL-003, DEL-014 | Must | Done |
| REQ-011 | CAP-008 | FEAT-017 | DEL-008 | Should | Done |
| REQ-012 | CAP-004, CAP-007 | FEAT-004, FEAT-008 | DEL-001 | Should | Done |
| REQ-013 | CAP-010 | FEAT-013 | DEL-005, DEL-008 | Should | Done |
| REQ-014 | CAP-008 | FEAT-019 | DEL-008 | Should | Done |
| REQ-015 | CAP-009 | FEAT-012 | DEL-014 | Nice | Done |
| REQ-016 | CAP-011 | FEAT-014 | DEL-004 | Nice | Done |
| REQ-017 | CAP-012 | FEAT-015 | DEL-011–013, DEL-016, DEL-017 | Must | Done |

## Coverage Analysis

- **17/17 requirements** traced to capabilities (100%)
- **12/12 capabilities** traced to features (100%)
- **20/20 features** traced to deliverables (100%)
- **0 orphan requirements**
- **0 orphan capabilities**
- **0 orphan features**

## Release Plan

| Release | Features | Focus | Status |
|---------|----------|-------|--------|
| **v1.0 — Core Demo** | FEAT-001 through FEAT-007, FEAT-009–012, FEAT-015–016 | Core AI pipeline, demo playback, 3-panel UI | Done |
| **v1.1 — Enhanced UX** | FEAT-002, FEAT-013, FEAT-017–020 | Diarization, config panel, transcript bubbles, animations | Done |
| **v1.2 — AI Recommendations** | FEAT-008 | LLM-powered resolution suggestions | Done |
| **v2.0 — Production Path** | FEAT-014 + auth + session persistence + TLS | Live mic, security, multi-user | Planned |

## Assumptions & Constraints

| # | Assumption/Constraint |
|---|----------------------|
| 1 | Snowflake account has Cortex AI function access enabled |
| 2 | Hybrid tables are available in the account's region |
| 3 | Demo runs single-user (no concurrent session support) |
| 4 | No authentication required (demo use case only) |
| 5 | Audio must be mono MP3 for AI_TRANSCRIBE compatibility |
| 6 | ffmpeg is available on the deployment machine |
| 7 | Stage must use SNOWFLAKE_SSE encryption for AI functions |
| 8 | Python 3.10+ and Node.js 18+ available |

## Open Questions

| # | Question | Impact |
|---|----------|--------|
| 1 | Should the demo support concurrent sessions for multi-user demos? | Architecture: would need session isolation |
| 2 | Is Docker packaging needed for portability? | DevOps: Dockerfile + docker-compose |
| 3 | Should the UI support dark mode? | UX: CSS variable theming |
| 4 | Should recommendations be persisted to a table for analytics? | Data: new CALL_RECOMMENDATIONS table |
