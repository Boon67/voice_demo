export default function SimilarCases({ cases }) {
  if (!cases || cases.length === 0) return null;

  return (
    <div className="card">
      <div className="card-header">
        Similar Cases Detected{' '}
        <span className={`badge-count ${cases.length >= 3 ? 'red' : ''}`}>
          {cases.length} found
        </span>
        <button className="btn btn-sm">Hide</button>
      </div>
      <div className="card-body">
        {cases.map((c, i) => (
          <div key={i} className={`case-card ${c.status} ${c.priority}`}>
            <div className="case-header">
              <div>
                <span className="case-number">{c.case_number}</span>{' '}
                <span className={`status-badge ${c.status}`}>{c.status}</span>{' '}
                <span className={`priority-badge ${c.priority}`}>{c.priority}</span>
              </div>
              <div>
                <div className="match-score" style={{ color: c.match_score > 0.5 ? '#f59e0b' : '#94a3b8' }}>
                  {Math.round(c.match_score * 100)}%
                </div>
                <div className="match-label">match</div>
              </div>
            </div>
            <div className="case-title">{truncate(c.issue_description, 60)}</div>
            <div className="case-desc">{c.issue_description}</div>
            <div className="case-meta">
              Customer: {c.customer_name} · Product: {c.product_name} · Type: {c.case_type} · Opened: {c.opened_date}
            </div>
            {c.resolution && (
              <div className="case-resolution">
                <b>Resolution:</b> {c.resolution}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

function truncate(s, len) {
  if (!s) return '';
  return s.length > len ? s.substring(0, len) + '...' : s;
}
