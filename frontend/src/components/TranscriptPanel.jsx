import { useEffect, useRef } from 'react';

export default function TranscriptPanel({ messages, callerName, open, onToggle }) {
  const bottomRef = useRef(null);

  useEffect(() => {
    if (bottomRef.current) {
      bottomRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [messages]);

  if (!open) return null;

  let lastSpeaker = null;

  return (
    <div className="transcript-panel">
      <div className="transcript-panel-header">
        <span>Live Transcript</span>
        <button className="transcript-close" onClick={onToggle}>✕</button>
      </div>
      <div className="transcript-messages">
        {messages.length === 0 && (
          <div className="transcript-empty">Waiting for call to begin...</div>
        )}
        {messages.map((msg, i) => {
          const showLabel = msg.speaker !== lastSpeaker;
          lastSpeaker = msg.speaker;
          const isAgent = msg.speaker === 'agent';
          const label = isAgent ? 'Agent' : callerName;

          return (
            <div key={i} className={`bubble-row ${isAgent ? 'bubble-row-left' : 'bubble-row-right'}`}>
              {showLabel && (
                <div className={`speaker-label ${isAgent ? 'label-left' : 'label-right'}`}>
                  {label}
                </div>
              )}
              <div className={`message-bubble ${isAgent ? 'bubble-agent' : 'bubble-caller'}`}>
                {msg.text}
              </div>
            </div>
          );
        })}
        <div ref={bottomRef} />
      </div>
    </div>
  );
}
