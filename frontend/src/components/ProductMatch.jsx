export default function ProductMatch({ products }) {
  if (!products || products.length === 0) return null;

  return (
    <div className="card">
      <div className="card-header">
        Product Identified from Order History
        <button className="btn btn-sm">Hide</button>
      </div>
      <div className="card-body">
        {products.map((p, i) => (
          <div key={i} className="product-card">
            <div className="product-info">
              <h4>
                {p.product_name}{' '}
                <span style={{ color: '#94a3b8', fontSize: '0.75rem' }}>{p.sku}</span>
              </h4>
              <div className="product-meta">
                Category: {p.category}  Price: ${p.price?.toFixed(2)}  Qty: {p.quantity}
              </div>
              <div className="product-meta" style={{ marginTop: 4 }}>
                Order: <b>{p.order_number}</b>{' '}
                <span className={`status-badge ${p.order_status}`}>{p.order_status}</span>{' '}
                Date: {p.order_date}
                {p.tracking_number && ` Tracking: ${p.tracking_number}`}
              </div>
            </div>
            <div>
              <div className="match-score" style={{ color: p.match_score > 0.7 ? '#22c55e' : p.match_score > 0.5 ? '#f59e0b' : '#94a3b8' }}>
                {Math.round(p.match_score * 100)}%
              </div>
              <div className="match-label">match</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
