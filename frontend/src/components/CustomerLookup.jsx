import { useState } from 'react';

const API = 'http://localhost:8080';

export default function CustomerLookup({ matchedCustomer, matchedOrders }) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState(null);
  const [searching, setSearching] = useState(false);

  const customer = matchedCustomer || (results && results.length > 0 ? results[0].customer : null);
  const orders = matchedOrders || (results && results.length > 0 ? results[0].orders : null);

  const search = async () => {
    if (!query.trim()) return;
    setSearching(true);
    try {
      const res = await fetch(`${API}/api/customers/search`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query }),
      });
      const data = await res.json();
      setResults(data.results || []);
    } catch (e) { console.error(e); }
    setSearching(false);
  };

  return (
    <div className="card">
      <div className="card-header">Customer Lookup</div>
      <div className="card-body">
        <div style={{ fontSize: '0.8rem', color: '#64748b', marginBottom: 4 }}>
          Search (name, phone, or email):
        </div>
        <div className="search-row">
          <input
            value={matchedCustomer ? matchedCustomer.name : query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && search()}
            placeholder="Search customers..."
          />
          <button className="search-btn" onClick={search} disabled={searching}>
            {searching ? '...' : 'Search'}
          </button>
        </div>
        {customer && (
          <>
            <div className="customer-details">
              <h4>Customer Details</h4>
              <div className="detail-row"><span className="label">Name:</span><span>{customer.name}</span></div>
              <div className="detail-row"><span className="label">Email:</span><span>{customer.email}</span></div>
              <div className="detail-row"><span className="label">Phone:</span><span>{customer.phone}</span></div>
              <div className="detail-row"><span className="label">Loyalty:</span><span>{customer.loyalty_tier}</span></div>
              <div className="detail-row"><span className="label">Address:</span><span>{customer.address}</span></div>
            </div>
            {orders && orders.length > 0 && (
              <>
                <h4 style={{ fontSize: '0.85rem', color: '#0d3b66', marginBottom: 8 }}>
                  Recent Orders ({orders.length})
                </h4>
                {orders.map((o, i) => (
                  <div key={i} className="order-card">
                    <div className="order-header">
                      <span className="order-number">{o.order_number}</span>
                      <span className={`status-badge ${o.status}`}>{o.status}</span>
                    </div>
                    <div className="order-meta">
                      Date: {o.order_date}  Total: ${o.total?.toFixed(2)}
                      {o.tracking_number && `  Tracking: ${o.tracking_number}`}
                    </div>
                    {o.items && o.items.map((item, j) => (
                      <div key={j} className="order-items">
                        {item.quantity}x {item.product_name} (${item.price?.toFixed(2)})
                      </div>
                    ))}
                  </div>
                ))}
              </>
            )}
          </>
        )}
        {!customer && <div className="empty-state">Search for a customer or wait for AI auto-detection</div>}
      </div>
    </div>
  );
}
