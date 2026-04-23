import AnimatedCard from './AnimatedCard';

export default function SimilarCases({ cases }) {
  if (!cases || cases.length === 0) return null;

  const scoreClass = (s) => s > 0.6 ? 'high' : s > 0.45 ? 'medium' : 'low';

  return (
    <AnimatedCard>
      <div className="card-header">
        <span>
          <span className="card-header-icon">🔗</span>
          Similar Cases
          <span className="badge-count" style={{ marginLeft: 8 }}>{cases.length}</span>
        </span>
        <span className="ai-tag">AI_SIMILARITY</span>
      </div>
      <div className="card-body">
        {cases.slice(0, 5).map((c, i) => (
          <div key={i} className={`case-card ${c.status} ${c.priority}`}>
            <div className="case-header">
              <div className="case-badges">
                <span className="case-number">{c.case_number}</span>
                <span className={`status-badge ${c.status}`}>{c.status}</span>
                <span className={`priority-badge ${c.priority}`}>{c.priority}</span>
              </div>
              <div className={`match-score-badge ${scoreClass(c.match_score)}`} style={{ width: 40, height: 40, fontSize: '0.75rem' }}>
                {Math.round(c.match_score * 100)}%
                <span className="match-score-label">match</span>
              </div>
            </div>
            <div className="case-desc">{c.issue_description}</div>
            <div className="case-meta">
              {c.customer_name} · {c.product_name} · {c.case_type} · {c.opened_date}
            </div>
            {c.resolution && (
              <div className="case-resolution">
                <b>Resolution:</b> {c.resolution}
              </div>
            )}
          </div>
        ))}
      </div>
    </AnimatedCard>
  );
}
