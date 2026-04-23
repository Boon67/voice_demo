export default function Header({ health, wsConnected, callActive, callId }) {
  return (
    <div className="header">
      <div className="header-left">
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
      </div>
    </div>
  );
}
