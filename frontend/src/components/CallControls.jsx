import { useState, useRef, useEffect } from 'react';

const API = 'http://localhost:8080';

const MODEL_OPTIONS = [
  'llama3.1-8b', 'llama3.1-70b', 'llama3.1-405b', 'llama3.3-70b',
  'llama4-maverick', 'llama4-scout',
  'mistral-large2', 'deepseek-r1',
  'snowflake-arctic', 'snowflake-llama-3.1-405b', 'snowflake-llama-3.3-70b',
  'claude-3-5-sonnet', 'claude-3-7-sonnet', 'claude-4-sonnet', 'claude-4-opus',
  'claude-haiku-4-5', 'claude-sonnet-4-5', 'claude-opus-4-5',
  'claude-sonnet-4-6', 'claude-opus-4-6', 'claude-sonnet-4-7', 'claude-opus-4-7',
  'openai-gpt-4.1', 'openai-gpt-5', 'openai-gpt-5-mini', 'openai-gpt-5-nano', 'openai-gpt-5.1', 'openai-o4-mini',
  'gemini-2.5-flash', 'gemini-2.5-flash-lite', 'gemini-3.1-pro',
];

export default function CallControls({ callId, isPlaying, playbackProgress, onPlaybackStart, onReset }) {
  const [recordings, setRecordings] = useState([]);
  const [selectedRecording, setSelectedRecording] = useState('demo_call');
  const [starting, setStarting] = useState(false);
  const [resetting, setResetting] = useState(false);
  const audioRef = useRef(null);
  const [audioTime, setAudioTime] = useState(0);
  const [configOpen, setConfigOpen] = useState(false);
  const [cfg, setCfg] = useState(null);

  useEffect(() => {
    fetch(`${API}/api/recordings`)
      .then(r => r.json())
      .then(data => {
        setRecordings(data);
        if (data.length > 0) setSelectedRecording(data[0].id);
      })
      .catch(() => {});
    fetch(`${API}/api/config`).then(r => r.json()).then(setCfg).catch(() => {});
  }, []);

  useEffect(() => {
    if (!isPlaying && audioRef.current) {
      audioRef.current.pause();
      audioRef.current = null;
      setAudioTime(0);
    }
  }, [isPlaying]);

  const playRecording = async () => {
    setStarting(true);
    try {
      const res = await fetch(`${API}/api/calls/play-recording`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ recording_id: selectedRecording }),
      });
      const data = await res.json();
      if (data.error) { setStarting(false); return; }
      const audio = new Audio(`${API}/api/audio/${selectedRecording}.mp3?t=${Date.now()}`);
      audio.volume = 1.0;
      audioRef.current = audio;
      audio.ontimeupdate = () => setAudioTime(audio.currentTime);
      audio.onended = () => setAudioTime(0);
      await audio.play();
      if (onPlaybackStart) onPlaybackStart(data);
    } catch (e) { console.error(e); }
    setStarting(false);
  };

  const stopPlayback = async () => {
    if (audioRef.current) { audioRef.current.pause(); audioRef.current = null; setAudioTime(0); }
    try { await fetch(`${API}/api/calls/stop`, { method: 'POST' }); } catch (e) { console.error(e); }
  };

  const handleReset = async () => {
    setResetting(true);
    if (audioRef.current) { audioRef.current.pause(); audioRef.current = null; setAudioTime(0); }
    if (onReset) await onReset();
    setResetting(false);
  };

  const updateConfig = async (key, value) => {
    const updated = { ...cfg, [key]: value };
    setCfg(updated);
    try {
      const res = await fetch(`${API}/api/config`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ [key]: value }),
      });
      setCfg(await res.json());
    } catch (e) { console.error(e); }
  };

  const formatTime = (s) => {
    const m = Math.floor(s / 60);
    const sec = Math.floor(s % 60);
    return `${m}:${sec.toString().padStart(2, '0')}`;
  };

  const busy = isPlaying || starting || resetting;

  return (
    <div className="sidebar">
      <div className="sidebar-section">
        <div className="sidebar-section-title">Demo Recording</div>
        <select
          className="sidebar-select"
          value={selectedRecording}
          onChange={e => setSelectedRecording(e.target.value)}
          disabled={busy}
        >
          {recordings.map(r => (
            <option key={r.id} value={r.id}>{r.label}</option>
          ))}
        </select>
        <div className="sidebar-btn-group">
          {isPlaying ? (
            <button className="sidebar-btn stop" onClick={stopPlayback}>Stop</button>
          ) : (
            <button className="sidebar-btn play" onClick={playRecording} disabled={busy}>
              {starting ? 'Starting...' : '▶ Play'}
            </button>
          )}
          <button className="sidebar-btn reset" onClick={handleReset} disabled={busy}>
            {resetting ? '...' : 'Reset'}
          </button>
        </div>

        {isPlaying && playbackProgress && (
          <div className="sidebar-progress">
            <div className="sidebar-progress-label">
              <span>Chunk {playbackProgress.chunk}/{playbackProgress.total}</span>
              <span>{formatTime(audioTime)}</span>
            </div>
            <div className="sidebar-progress-bar">
              <div
                className="sidebar-progress-fill"
                style={{ width: `${(playbackProgress.chunk / playbackProgress.total) * 100}%` }}
              />
            </div>
          </div>
        )}
      </div>

      <div
        className="sidebar-config-toggle"
        onClick={() => setConfigOpen(o => !o)}
      >
        <span>⚙ Configuration</span>
        <span>{configOpen ? '▾' : '▸'}</span>
      </div>

      {configOpen && cfg && (
        <div className="sidebar-config-body">
          <label>
            <span>Audio Segment (sec)</span>
            <input
              type="number" min={5} max={60}
              value={cfg.segment_seconds}
              onChange={e => updateConfig('segment_seconds', Number(e.target.value))}
            />
          </label>
          <label>
            <span>Diarization Model</span>
            <select
              value={cfg.diarization_model}
              onChange={e => updateConfig('diarization_model', e.target.value)}
            >
              {MODEL_OPTIONS.map(m => <option key={m} value={m}>{m}</option>)}
            </select>
          </label>
          <label>
            <span>Product Threshold</span>
            <input
              type="number" min={0.1} max={1.0} step={0.05}
              value={cfg.similarity_threshold_product}
              onChange={e => updateConfig('similarity_threshold_product', Number(e.target.value))}
            />
          </label>
          <label>
            <span>Case Threshold</span>
            <input
              type="number" min={0.1} max={1.0} step={0.05}
              value={cfg.similarity_threshold_case}
              onChange={e => updateConfig('similarity_threshold_case', Number(e.target.value))}
            />
          </label>
        </div>
      )}

      <div style={{ flex: 1 }} />

      <div style={{ padding: '12px 16px', fontSize: '0.62rem', color: 'rgba(255,255,255,0.2)', textAlign: 'center' }}>
        Powered by Snowflake Cortex AI
      </div>
    </div>
  );
}
