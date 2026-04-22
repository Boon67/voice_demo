export default function Header({ health, wsConnected, onRefresh, onReconnect, transcriptOpen, onTranscriptToggle, messageCount }) {
  return (
    <div className="header">
      <div>
        <h1><b>Call Center AI Demo</b> <span>Powered by Snowflake</span></h1>
        <div className="subtitle">Real-time transcription · AI extraction · Semantic case matching</div>
      </div>
      <div className="header-right">
        <span className="status-pill">
          <span className={`status-dot ${health.backend ? 'ok' : 'err'}`} />
          Backend
        </span>
        <span className="status-pill">
          <span className={`status-dot ${health.snowflake ? 'ok' : 'err'}`} />
          Snowflake
        </span>
        <span className="status-pill">
          <span className={`status-dot ${health.audio ? 'ok' : 'err'}`} />
          Audio
        </span>
        <span className="status-pill">
          <span className={`status-dot ${wsConnected ? 'ok' : 'err'}`} />
          WebSocket
        </span>
        <button className={`btn transcript-toggle-btn ${transcriptOpen ? 'active' : ''}`} onClick={onTranscriptToggle}>
          💬 {messageCount > 0 && <span className="msg-count">{messageCount}</span>}
        </button>
        <button className="btn" onClick={onRefresh}>Refresh</button>
        <button className="btn" onClick={onReconnect}>Reconnect WS</button>
      </div>
    </div>
  );
}
