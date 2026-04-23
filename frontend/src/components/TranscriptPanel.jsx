import { useEffect, useRef, useMemo, useState } from 'react';

export default function TranscriptPanel({ messages, callerName, isPlaying, playbackProgress }) {
  const bottomRef = useRef(null);
  const [elapsed, setElapsed] = useState(0);
  const timerRef = useRef(null);

  const grouped = useMemo(() => {
    const groups = [];
    for (const msg of messages) {
      const last = groups[groups.length - 1];
      if (last && last.speaker === msg.speaker) {
        last.text += ' ' + msg.text;
      } else {
        groups.push({ speaker: msg.speaker, text: msg.text });
      }
    }
    return groups;
  }, [messages]);

  useEffect(() => {
    if (bottomRef.current) {
      bottomRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [grouped]);

  useEffect(() => {
    if (isPlaying) {
      setElapsed(0);
      timerRef.current = setInterval(() => setElapsed(e => e + 1), 1000);
    } else {
      if (timerRef.current) clearInterval(timerRef.current);
    }
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, [isPlaying]);

  const formatTime = (s) => {
    const m = Math.floor(s / 60);
    const sec = s % 60;
    return `${m}:${sec.toString().padStart(2, '0')}`;
  };

  return (
    <div className="transcript-col">
      <div className="transcript-header">
        <span>Live Transcript</span>
        <span className={`transcript-timer ${isPlaying ? 'active' : ''}`}>
          {isPlaying ? formatTime(elapsed) : grouped.length > 0 ? `${grouped.length} turns` : ''}
        </span>
      </div>
      <div className="transcript-messages">
        {grouped.length === 0 ? (
          <div className="transcript-empty">
            <div className="transcript-empty-icon">💬</div>
            <span>Waiting for call to begin...</span>
          </div>
        ) : (
          <>
            {grouped.map((group, i) => {
              const isAgent = group.speaker === 'agent';
              const label = isAgent ? 'Agent' : callerName;
              return (
                <div key={i} className={`bubble-row ${isAgent ? 'bubble-row-left' : 'bubble-row-right'}`}>
                  <div className={`speaker-label ${isAgent ? 'label-left' : 'label-right'}`}>
                    {label}
                  </div>
                  <div className={`message-bubble ${isAgent ? 'bubble-agent' : 'bubble-caller'}`}>
                    {group.text}
                  </div>
                </div>
              );
            })}
            <div ref={bottomRef} />
          </>
        )}
      </div>
    </div>
  );
}
