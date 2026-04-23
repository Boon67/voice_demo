import { useEffect, useRef, useMemo } from 'react';

export default function TranscriptPanel({ messages, callerName, open, onToggle }) {
  const bottomRef = useRef(null);

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

  if (!open) return null;

  return (
    <div className="transcript-panel">
      <div className="transcript-panel-header">
        <span>Live Transcript</span>
        <button className="transcript-close" onClick={onToggle}>✕</button>
      </div>
      <div className="transcript-messages">
        {grouped.length === 0 && (
          <div className="transcript-empty">Waiting for call to begin...</div>
        )}
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
      </div>
    </div>
  );
}
