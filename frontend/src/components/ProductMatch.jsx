import AnimatedCard from './AnimatedCard';

export default function ProductMatch({ products, domain }) {
  if (!products || products.length === 0) return null;

  const scoreClass = (s) => s > 0.7 ? 'high' : s > 0.5 ? 'medium' : 'low';
  const isInsurance = domain === 'insurance';

  return (
    <AnimatedCard>
      <div className="card-header">
        <span><span className="card-header-icon">{isInsurance ? '🚗' : '📦'}</span>{isInsurance ? 'Vehicle Matched from Agreements' : 'Product Identified from Orders'}</span>
        <span className="ai-tag">AI_SIMILARITY</span>
      </div>
      <div className="card-body">
        {products.map((p, i) => (
          <div key={i} className="product-card">
            <div className="product-info">
              <h4>{p.product_name}</h4>
              <span className="product-sku">{p.sku} · {p.category} · ${p.price?.toFixed(2)}{isInsurance ? '/day' : ''}</span>
              <div className="product-meta">
                {isInsurance ? 'Agreement' : 'Order'} <b>{p.order_number}</b>{' '}
                <span className={`status-badge ${p.order_status}`}>{p.order_status}</span>{' '}
                · {p.order_date}
                {!isInsurance && p.tracking_number && ` · Tracking: ${p.tracking_number}`}
                {isInsurance && p.tracking_number && ` · ${p.tracking_number}`}
              </div>
            </div>
            <div key={p.match_score} className={`match-score-badge ${scoreClass(p.match_score)} flash`}>
              {Math.round(p.match_score * 100)}%
              <span className="match-score-label">match</span>
            </div>
          </div>
        ))}
      </div>
    </AnimatedCard>
  );
}
