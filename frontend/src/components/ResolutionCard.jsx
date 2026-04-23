import AnimatedCard from './AnimatedCard';

const ICONS = {
  refund: '💰',
  replace: '📦',
  upgrade: '⬆️',
  discount: '🏷️',
  escalate: '📞',
  repair: '🔧',
  credit: '💳',
  exchange: '🔄',
  tow: '🚛',
  medical: '🏥',
  reimburse: '💰',
  subrogation: '⚖️',
};

const CONFIDENCE_CLASS = {
  high: 'rec-confidence-high',
  medium: 'rec-confidence-medium',
  low: 'rec-confidence-low',
};

export default function ResolutionCard({ recommendations, domain }) {
  if (!recommendations || recommendations.length === 0) return null;
  const isInsurance = domain === 'insurance';

  return (
    <AnimatedCard>
      <div className="card-header">
        <span>
          <span className="card-header-icon">💡</span>
          {isInsurance ? 'AI Claims Recommendations' : 'AI Resolution Recommendations'}
          <span className="badge-count" style={{ marginLeft: 8 }}>{recommendations.length}</span>
        </span>
        <span className="ai-tag">AI_COMPLETE</span>
      </div>
      <div className="card-body">
        {recommendations.map((rec, i) => (
          <div key={i} className="rec-card">
            <div className="rec-header">
              <div className="rec-icon">{ICONS[rec.icon] || '📋'}</div>
              <div className="rec-title-group">
                <div className="rec-action">{rec.action}</div>
                <div className={`rec-confidence ${CONFIDENCE_CLASS[rec.confidence] || ''}`}>
                  {rec.confidence} confidence
                </div>
              </div>
              <div className="rec-rank">#{i + 1}</div>
            </div>
            <div className="rec-description">{rec.description}</div>
            <div className="rec-reasoning">
              <span className="rec-reasoning-label">Reasoning:</span> {rec.reasoning}
            </div>
          </div>
        ))}
      </div>
    </AnimatedCard>
  );
}
