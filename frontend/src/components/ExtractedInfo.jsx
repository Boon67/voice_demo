import { useState } from 'react';

export default function ExtractedInfo({ candidates }) {
  const [showCandidates, setShowCandidates] = useState(true);

  if (!candidates || candidates.length === 0) {
    return (
      <div className="card">
        <div className="card-header">Snowflake Extracted Information</div>
        <div className="card-body">
          <div className="empty-state">No AI-extracted information available yet.</div>
        </div>
      </div>
    );
  }

  return (
    <div className="card">
      <div className="card-header">
        Snowflake Extracted Information
        <button className="btn btn-sm" onClick={() => setShowCandidates(!showCandidates)}>
          {showCandidates ? 'Hide' : 'Show'} Candidates
        </button>
      </div>
      {showCandidates && (
        <div className="card-body">
          <div className="candidates-grid">
            {candidates.map((c, i) => (
              <div key={i} className="candidate-item">
                <div className="candidate-field">{c.field_name.replace(/_/g, ' ')}</div>
                <div className="candidate-value">{c.field_value}</div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
