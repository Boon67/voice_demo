import { useState, useEffect } from 'react';

const API = 'http://localhost:8080';

const MODEL_OPTIONS = [
  'llama3.1-8b',
  'llama3.1-70b',
  'llama3.1-405b',
  'llama3.3-70b',
  'llama4-maverick',
  'llama4-scout',
  'mistral-large2',
  'deepseek-r1',
  'snowflake-arctic',
  'snowflake-llama-3.1-405b',
  'snowflake-llama-3.3-70b',
  'claude-3-5-sonnet',
  'claude-3-7-sonnet',
  'claude-4-sonnet',
  'claude-4-opus',
  'claude-haiku-4-5',
  'claude-sonnet-4-5',
  'claude-opus-4-5',
  'claude-sonnet-4-6',
  'claude-opus-4-6',
  'claude-sonnet-4-7',
  'claude-opus-4-7',
  'openai-gpt-4.1',
  'openai-gpt-5',
  'openai-gpt-5-mini',
  'openai-gpt-5-nano',
  'openai-gpt-5.1',
  'openai-o4-mini',
  'gemini-2.5-flash',
  'gemini-2.5-flash-lite',
  'gemini-3.1-pro',
];

export default function ConfigPanel() {
  const [cfg, setCfg] = useState(null);
  const [open, setOpen] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetch(`${API}/api/config`).then(r => r.json()).then(setCfg).catch(() => {});
  }, []);

  if (!cfg) return null;

  const save = async (updates) => {
    setSaving(true);
    try {
      const res = await fetch(`${API}/api/config`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(updates),
      });
      const data = await res.json();
      setCfg(data);
    } catch (e) {
      console.error(e);
    }
    setSaving(false);
  };

  const handleChange = (key, value) => {
    const updated = { ...cfg, [key]: value };
    setCfg(updated);
    save({ [key]: value });
  };

  return (
    <div className="config-panel">
      <div className="config-toggle" onClick={() => setOpen(o => !o)}>
        ⚙️ Configuration {open ? '▾' : '▸'}
      </div>
      {open && (
        <div className="config-grid">
          <label>
            <span>Audio Segment (sec)</span>
            <input
              type="number"
              min={5}
              max={60}
              value={cfg.segment_seconds}
              onChange={e => handleChange('segment_seconds', Number(e.target.value))}
            />
          </label>
          <label>
            <span>Diarization Model</span>
            <select
              value={cfg.diarization_model}
              onChange={e => handleChange('diarization_model', e.target.value)}
            >
              {MODEL_OPTIONS.map(m => <option key={m} value={m}>{m}</option>)}
            </select>
          </label>
          <label>
            <span>Product Match Threshold</span>
            <input
              type="number"
              min={0.1}
              max={1.0}
              step={0.05}
              value={cfg.similarity_threshold_product}
              onChange={e => handleChange('similarity_threshold_product', Number(e.target.value))}
            />
          </label>
          <label>
            <span>Case Match Threshold</span>
            <input
              type="number"
              min={0.1}
              max={1.0}
              step={0.05}
              value={cfg.similarity_threshold_case}
              onChange={e => handleChange('similarity_threshold_case', Number(e.target.value))}
            />
          </label>
          <label>
            <span>Enrichment Min Chars</span>
            <input
              type="number"
              min={50}
              max={500}
              step={10}
              value={cfg.enrichment_min_chars}
              onChange={e => handleChange('enrichment_min_chars', Number(e.target.value))}
            />
          </label>
          {saving && <span className="config-saving">Saving...</span>}
        </div>
      )}
    </div>
  );
}
