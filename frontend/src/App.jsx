import { useState, useEffect, useCallback } from 'react';
import './styles/App.css';
import useWebSocket from './hooks/useWebSocket';
import Header from './components/Header';
import CallSimulator from './components/CallSimulator';
import TranscriptPanel from './components/TranscriptPanel';
import CustomerLookup from './components/CustomerLookup';
import ExtractedInfo from './components/ExtractedInfo';
import ProductMatch from './components/ProductMatch';
import SimilarCases from './components/SimilarCases';
import CallDetails from './components/CallDetails';
import ConfigPanel from './components/ConfigPanel';

const API = 'http://localhost:8080';

function App() {
  const { connected, messageQueue, clearQueue, reconnect } = useWebSocket();
  const [health, setHealth] = useState({ backend: false, snowflake: false, audio: false });
  const [callId, setCallId] = useState(null);
  const [messages, setMessages] = useState([]);
  const [callerName, setCallerName] = useState('Unknown');
  const [transcriptOpen, setTranscriptOpen] = useState(true);
  const [candidates, setCandidates] = useState([]);
  const [extracted, setExtracted] = useState(null);
  const [customer, setCustomer] = useState(null);
  const [orders, setOrders] = useState(null);
  const [products, setProducts] = useState(null);
  const [similarCases, setSimilarCases] = useState(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [playbackProgress, setPlaybackProgress] = useState(null);

  const checkHealth = useCallback(async () => {
    try {
      const res = await fetch(`${API}/api/health`);
      const data = await res.json();
      setHealth(data);
    } catch {
      setHealth({ backend: false, snowflake: false, audio: false });
    }
  }, []);

  useEffect(() => {
    checkHealth();
    const interval = setInterval(checkHealth, 30000);
    return () => clearInterval(interval);
  }, [checkHealth]);

  useEffect(() => {
    if (messageQueue.length === 0) return;
    const batch = [...messageQueue];
    clearQueue();

    for (const msg of batch) {
      switch (msg.type) {
        case 'call_started':
          setCallId(msg.call_id);
          setMessages([]);
          setCallerName('Unknown');
          setCandidates([]);
          setExtracted(null);
          setCustomer(null);
          setOrders(null);
          setProducts(null);
          setSimilarCases(null);
          setTranscriptOpen(true);
          break;
        case 'transcript_update':
          setMessages(prev => {
            const chunkId = String(msg.chunk);
            if (prev.some(m => m.chunk === chunkId)) return prev;
            const updated = [...prev, { text: msg.text, speaker: msg.speaker || 'caller', chunk: chunkId }];
            updated.sort((a, b) => {
              const [aMain, aSub] = a.chunk.split('.').map(Number);
              const [bMain, bSub] = b.chunk.split('.').map(Number);
              return aMain !== bMain ? aMain - bMain : (aSub || 0) - (bSub || 0);
            });
            return updated;
          });
          break;
        case 'extraction_update':
          setCandidates(msg.candidates || []);
          setExtracted(msg.extracted || null);
          break;
        case 'customer_match':
          setCustomer(msg.customer);
          setOrders(msg.orders);
          if (msg.customer && msg.customer.name) {
            setCallerName(msg.customer.name);
          }
          break;
        case 'product_match':
          setProducts(msg.products);
          break;
        case 'similar_cases':
          setSimilarCases(msg.cases);
          break;
        case 'playback_started':
          setIsPlaying(true);
          setPlaybackProgress({ chunk: 0, total: msg.total_chunks });
          break;
        case 'audio_progress':
          setPlaybackProgress({ chunk: msg.chunk, total: msg.total });
          break;
        case 'playback_ended':
          setIsPlaying(false);
          setPlaybackProgress(null);
          break;
        case 'call_ended':
          setIsPlaying(false);
          setPlaybackProgress(null);
          break;
        case 'app_reset':
          setCallId(null);
          setMessages([]);
          setCallerName('Unknown');
          setCandidates([]);
          setExtracted(null);
          setCustomer(null);
          setOrders(null);
          setProducts(null);
          setSimilarCases(null);
          setIsPlaying(false);
          setPlaybackProgress(null);
          break;
        default:
        break;
      }
    }
  }, [messageQueue, clearQueue]);

  const resetApp = useCallback(async () => {
    try {
      await fetch(`${API}/api/reset`, { method: 'POST' });
    } catch (e) {
      console.error(e);
    }
  }, []);

  const handlePlaybackStart = (data) => {
    setIsPlaying(true);
    setPlaybackProgress({ chunk: 0, total: data.total_chunks });
  };

  const hasResults = customer || products || similarCases;

  return (
    <div>
      <Header
        health={health}
        wsConnected={connected}
        onRefresh={checkHealth}
        onReconnect={reconnect}
        transcriptOpen={transcriptOpen}
        onTranscriptToggle={() => setTranscriptOpen(o => !o)}
        messageCount={messages.length}
      />
      <div className={`app-body ${transcriptOpen ? 'app-body-with-panel' : ''}`}>
        <CallDetails extracted={extracted} />

        {hasResults ? (
          <div className="three-col">
            <CustomerLookup matchedCustomer={customer} matchedOrders={orders} />
            <ProductMatch products={products} />
            <SimilarCases cases={similarCases} />
          </div>
        ) : (
          <CustomerLookup matchedCustomer={customer} matchedOrders={orders} />
        )}

        <div className="demo-separator">
          <span>Demo / Debug Tools Below</span>
        </div>

        <ExtractedInfo candidates={candidates} />

        <CallSimulator
          callId={callId}
          playbackProgress={playbackProgress}
          isPlaying={isPlaying}
          onPlaybackStart={handlePlaybackStart}
          onReset={resetApp}
        />

        <ConfigPanel />
      </div>

      <TranscriptPanel
        messages={messages}
        callerName={callerName}
        open={transcriptOpen}
        onToggle={() => setTranscriptOpen(false)}
      />
    </div>
  );
}

export default App;
