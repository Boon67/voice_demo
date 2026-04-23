export default function CustomerLookup({ matchedCustomer, matchedOrders }) {
  if (!matchedCustomer) return null;

  const customer = matchedCustomer;
  const orders = matchedOrders || [];
  const initials = customer.name ? customer.name.split(' ').map(n => n[0]).join('') : '?';

  return (
    <div className="card">
      <div className="card-header">
        <span><span className="card-header-icon">👤</span>Customer Identified</span>
        <span className="ai-tag">AI_SIMILARITY Match</span>
      </div>
      <div className="card-body">
        <div className="customer-header">
          <div className="customer-avatar">{initials}</div>
          <div className="customer-name-block">
            <div className="customer-name">{customer.name}</div>
            {customer.loyalty_tier && (
              <span className={`customer-tier ${customer.loyalty_tier}`}>{customer.loyalty_tier}</span>
            )}
          </div>
        </div>

        <div className="customer-info-grid">
          <div className="customer-info-item">
            <span className="customer-info-label">Email</span>
            <span className="customer-info-value">{customer.email}</span>
          </div>
          <div className="customer-info-item">
            <span className="customer-info-label">Phone</span>
            <span className="customer-info-value">{customer.phone}</span>
          </div>
          {customer.address && (
            <div className="customer-info-item" style={{ gridColumn: '1 / -1' }}>
              <span className="customer-info-label">Address</span>
              <span className="customer-info-value">{customer.address}</span>
            </div>
          )}
        </div>

        {orders.length > 0 && (
          <>
            <div className="orders-title">Recent Orders ({orders.length})</div>
            {orders.slice(0, 4).map((o, i) => (
              <div key={i} className="order-card">
                <div className="order-card-left">
                  <div className="order-number">{o.order_number}</div>
                  <div className="order-meta">
                    {o.order_date} · ${o.total?.toFixed(2)}
                    {o.items && o.items.map((item, j) => (
                      <span key={j} className="order-items"> · {item.quantity}x {item.product_name}</span>
                    ))}
                  </div>
                </div>
                <span className={`status-badge ${o.status}`}>{o.status}</span>
              </div>
            ))}
          </>
        )}
      </div>
    </div>
  );
}
