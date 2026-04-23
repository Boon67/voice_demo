export default function Header({ health, wsConnected, callActive, callId, onToggleSidebar, onToggleTranscript, sidebarOpen, transcriptOpen, messageCount }) {
  return (
    <div className="header">
      <div className="header-left">
        <button className={`drawer-toggle ${sidebarOpen ? 'active' : ''}`} onClick={onToggleSidebar} title="Demo Controls">
          🎙️
        </button>
        <div className="header-logo">
          Call Center AI<span>Agent Assist</span>
        </div>
      </div>

      <div className="header-center">
        <div className={`call-status-indicator ${callActive ? 'active' : 'idle'}`}>
          <span className={`call-status-dot ${callActive ? 'active' : 'idle'}`} />
          {callActive ? `Live Call · ${callId || ''}` : 'No Active Call'}
        </div>
      </div>

      <div className="header-right">
        <span className={`conn-dot ${health.backend ? 'ok' : 'err'}`} />
        <span className="conn-label">API</span>
        <span className={`conn-dot ${health.snowflake ? 'ok' : 'err'}`} />
        <span className="conn-label">Snowflake</span>
        <span className={`conn-dot ${wsConnected ? 'ok' : 'err'}`} />
        <span className="conn-label">WS</span>
        <button className={`drawer-toggle ${transcriptOpen ? 'active' : ''}`} onClick={onToggleTranscript} title="Live Transcript">
          💬
          {messageCount > 0 && <span className="drawer-toggle-badge">{messageCount}</span>}
        </button>
      </div>
    </div>
  );
}
