import AnimatedCard from './AnimatedCard';

export default function CallSummary({ extracted, domain }) {
  const val = (key) => {
    if (!extracted) return '';
    const v = extracted[key];
    return v && v.toLowerCase() !== 'none' && v.toLowerCase() !== 'null' && v.toLowerCase() !== 'n/a' ? v : '';
  };

  if (!extracted) return null;

  const isInsurance = domain === 'insurance';

  const fields = isInsurance ? [
    { label: 'Policyholder', value: val('customer_name') },
    { label: 'Phone', value: val('customer_phone') },
    { label: 'Email', value: val('customer_email') },
    { label: 'Policy #', value: val('policy_number') },
    { label: 'Vehicle', value: val('product_name') },
    { label: 'Incident', value: val('issue_description') },
    { label: 'Location', value: val('accident_location') },
    { label: 'Damage', value: val('damage_description') },
    { label: 'Injuries', value: val('injury_reported') },
    { label: 'Police Report', value: val('police_report_number') },
    { label: 'Requested', value: val('resolution_requested') },
  ].filter(f => f.value) : [
    { label: 'Customer', value: val('customer_name') },
    { label: 'Phone', value: val('customer_phone') },
    { label: 'Email', value: val('customer_email') },
    { label: 'Product', value: val('product_name') },
    { label: 'Issue', value: val('issue_description') },
    { label: 'Order #', value: val('order_number') },
    { label: 'Resolution', value: val('resolution_requested') },
    { label: 'Return Reason', value: val('return_reason') },
  ].filter(f => f.value);

  if (fields.length === 0) return null;

  return (
    <AnimatedCard>
      <div className="card-header">
        <span><span className="card-header-icon">{isInsurance ? '📋' : '🔍'}</span>{isInsurance ? 'AI-Extracted FNOL Summary' : 'AI-Extracted Call Summary'}</span>
        <span className="ai-tag">Snowflake AI_EXTRACT</span>
      </div>
      <div className="card-body">
        <div className="summary-grid">
          {fields.map((f, i) => (
            <div key={i} className="summary-item">
              <div className="summary-label">{f.label}</div>
              <div className="summary-value">{f.value}</div>
            </div>
          ))}
        </div>
      </div>
    </AnimatedCard>
  );
}
