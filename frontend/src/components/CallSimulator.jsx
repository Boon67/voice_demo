import { useState, useRef, useEffect } from 'react';

const API = 'http://localhost:8080';


export default function CallSimulator({ callId, playbackProgress, isPlaying, onPlaybackStart, onReset }) {
  const [open, setOpen] = useState(true);
  const [text, setText] = useState('');
  const [sending, setSending] = useState(false);
  const [starting, setStarting] = useState(false);
  const [resetting, setResetting] = useState(false);
  const audioRef = useRef(null);
  const [audioTime, setAudioTime] = useState(0);
  const [recordings, setRecordings] = useState([]);
  const [selectedRecording, setSelectedRecording] = useState('demo_call');

  useEffect(() => {
    fetch(`${API}/api/recordings`)
      .then(r => r.json())
      .then(data => {
        setRecordings(data);
        if (data.length > 0) setSelectedRecording(data[0].id);
      })
      .catch(() => {});
  }, []);

  useEffect(() => {
    if (!isPlaying && audioRef.current) {
      audioRef.current.pause();
      audioRef.current = null;
      setAudioTime(0);
    }
  }, [isPlaying]);

  const send = async (t) => {
    const body = t || text;
    if (!body.trim()) return;
    setSending(true);
    try {
      await fetch(`${API}/api/calls/simulate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: body, call_id: callId }),
      });
      setText('');
    } catch (e) {
      console.error(e);
    }
    setSending(false);
  };

  const playRecording = async () => {
    setStarting(true);
    try {
      const res = await fetch(`${API}/api/calls/play-recording`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ recording_id: selectedRecording }),
      });
      const data = await res.json();
      if (data.error) {
        console.error(data.error);
        setStarting(false);
        return;
      }

      const audio = new Audio(`${API}/api/audio/${selectedRecording}.mp3?t=${Date.now()}`);
      audio.volume = 1.0;
      audioRef.current = audio;
      audio.ontimeupdate = () => setAudioTime(audio.currentTime);
      audio.onended = () => setAudioTime(0);
      await audio.play();

      if (onPlaybackStart) onPlaybackStart(data);
    } catch (e) {
      console.error(e);
    }
    setStarting(false);
  };

  const stopPlayback = async () => {
    if (audioRef.current) {
      audioRef.current.pause();
      audioRef.current = null;
      setAudioTime(0);
    }
    try {
      await fetch(`${API}/api/calls/stop`, { method: 'POST' });
    } catch (e) {
      console.error(e);
    }
  };

  const handleReset = async () => {
    setResetting(true);
    if (audioRef.current) {
      audioRef.current.pause();
      audioRef.current = null;
      setAudioTime(0);
    }
    if (onReset) await onReset();
    setText('');
    setResetting(false);
  };

  const busy = sending || isPlaying || starting || resetting;

  const formatTime = (s) => {
    const m = Math.floor(s / 60);
    const sec = Math.floor(s % 60);
    return `${m}:${sec.toString().padStart(2, '0')}`;
  };

  return (
    <div className="simulator-panel">
      <div className="simulator-header" onClick={() => setOpen(!open)}>
        <h3>Call Simulator</h3>
        <span>{open ? '▾' : '▸'}</span>
      </div>
      {open && (
        <div className="simulator-body">
          {isPlaying && playbackProgress && (
            <div className="playback-indicator">
              <div className="playback-status">
                <span className="playback-dot" />
                Playing Call Recording
                <span className="playback-time">{formatTime(audioTime)}</span>
              </div>
              <div className="playback-progress-bar">
                <div
                  className="playback-progress-fill"
                  style={{ width: `${(playbackProgress.chunk / playbackProgress.total) * 100}%` }}
                />
              </div>
              <div className="playback-meta">
                Processing chunk {playbackProgress.chunk} of {playbackProgress.total}
              </div>
            </div>
          )}
          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="Type what the caller says, or use a preset below..."
            disabled={isPlaying}
          />
          <div className="simulator-actions">
            {isPlaying ? (
              <button className="sim-btn stop" onClick={stopPlayback}>
                Stop Playback
              </button>
            ) : (
              <>
                <button className="sim-btn send" onClick={() => send()} disabled={busy}>
                  {sending ? 'Processing...' : 'Send to Pipeline'}
                </button>
                {recordings.length > 1 && (
                  <select
                    className="recording-select"
                    value={selectedRecording}
                    onChange={e => setSelectedRecording(e.target.value)}
                    disabled={busy}
                  >
                    {recordings.map(r => (
                      <option key={r.id} value={r.id}>{r.label}</option>
                    ))}
                  </select>
                )}
                <button
                  className="sim-btn play"
                  onClick={playRecording}
                  disabled={busy}
                >
                  {starting ? 'Starting...' : 'Play Recording'}
                </button>
              </>
            )}
            <button className="sim-btn reset" onClick={handleReset} disabled={resetting || isPlaying}>
              {resetting ? 'Resetting...' : 'Reset App'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
