import { useState, useRef, useEffect } from 'react';

const API = 'http://localhost:8080';

const PRESETS = [
  {
    label: 'Intro',
    text: "Hi, my name is Diana Prince. I'm calling about an issue with a product I purchased recently.",
  },
  {
    label: 'Details',
    text: "Yes, I bought some wireless noise-canceling headphones about a month ago. The left ear keeps cutting out. The audio just drops randomly and comes back. It started about a week after I got them. My email is diana.prince@gmail.com.",
  },
  {
    label: 'Escalate',
    text: "I've tried factory resetting them and using different devices but nothing works. I think it's a hardware defect. I'd like a replacement please. My order number was ORD-2026-901.",
  },
];

export default function CallSimulator({ callId, playbackProgress, isPlaying, onPlaybackStart }) {
  const [open, setOpen] = useState(true);
  const [text, setText] = useState('');
  const [sending, setSending] = useState(false);
  const [starting, setStarting] = useState(false);
  const audioRef = useRef(null);
  const [audioTime, setAudioTime] = useState(0);

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
      const res = await fetch(`${API}/api/calls/play-recording`, { method: 'POST' });
      const data = await res.json();
      if (data.error) {
        console.error(data.error);
        setStarting(false);
        return;
      }

      const audio = new Audio(`${API}/api/audio/demo_call.mp3`);
      audioRef.current = audio;
      audio.ontimeupdate = () => setAudioTime(audio.currentTime);
      audio.onended = () => setAudioTime(0);
      audio.play().catch(console.error);

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

  const busy = sending || isPlaying || starting;

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
                <button
                  className="sim-btn play"
                  onClick={playRecording}
                  disabled={busy}
                >
                  {starting ? 'Starting...' : 'Play Recording'}
                </button>
              </>
            )}
            {!isPlaying && PRESETS.map((p, i) => (
              <button key={i} className="sim-btn preset" onClick={() => send(p.text)} disabled={busy}>
                {p.label}
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
