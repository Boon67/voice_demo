export default function CallDetails({ extracted }) {
  const val = (key) => {
    if (!extracted) return '';
    const v = extracted[key];
    return v && v.toLowerCase() !== 'none' && v.toLowerCase() !== 'null' && v.toLowerCase() !== 'n/a' ? v : '';
  };

  return (
    <div className="card">
      <div className="card-header">Call Details</div>
      <div className="card-body">
        <div className="call-details-grid">
          <div className="detail-section">
            <h4>Caller Information</h4>
            <label>Customer Name:</label>
            <input readOnly value={val('customer_name')} placeholder="Caller's name" />
            <label>Customer Phone:</label>
            <input readOnly value={val('customer_phone')} placeholder="Phone number" />
            <label>Customer Email:</label>
            <input readOnly value={val('customer_email')} placeholder="Email address" />
          </div>
          <div className="detail-section">
            <h4>Issue Details</h4>
            <label>Call Reason:</label>
            <input readOnly value={val('return_reason') || 'Product Issue'} placeholder="Select reason..." />
            <label>Issue Description:</label>
            <textarea readOnly value={val('issue_description')} placeholder="Issue details..." rows={3} />
          </div>
          <div className="detail-section">
            <h4>Product / Order Info</h4>
            <label>Product Name:</label>
            <input readOnly value={val('product_name')} placeholder="Product mentioned" />
            <label>Order Number:</label>
            <input readOnly value={val('order_number')} placeholder="Order #" />
            <label>Return Reason:</label>
            <input readOnly value={val('return_reason')} placeholder="Return reason" />
          </div>
          <div className="detail-section">
            <h4>Resolution</h4>
            <label>Priority:</label>
            <input readOnly value="Medium" />
            <label>Resolution Requested:</label>
            <textarea readOnly value={val('resolution_requested')} placeholder="Resolution..." rows={3} />
            <label>Shipping Address:</label>
            <input readOnly value={val('shipping_address')} placeholder="Address" />
          </div>
        </div>
      </div>
    </div>
  );
}
