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

const API = 'http://localhost:8080';

function App() {
  const { connected, lastMessage, reconnect } = useWebSocket();
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
    if (!lastMessage) return;
    const msg = lastMessage;

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
          if (prev.some(m => m.chunk === msg.chunk)) return prev;
          const updated = [...prev, { text: msg.text, speaker: msg.speaker || 'caller', chunk: msg.chunk }];
          updated.sort((a, b) => a.chunk - b.chunk);
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
      default:
        break;
    }
  }, [lastMessage]);

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
        <CallSimulator
          callId={callId}
          playbackProgress={playbackProgress}
          isPlaying={isPlaying}
          onPlaybackStart={handlePlaybackStart}
        />

        {hasResults ? (
          <div className="three-col">
            <CustomerLookup matchedCustomer={customer} matchedOrders={orders} />
            <ProductMatch products={products} />
            <SimilarCases cases={similarCases} />
          </div>
        ) : (
          <CustomerLookup matchedCustomer={customer} matchedOrders={orders} />
        )}

        <ExtractedInfo candidates={candidates} />
        <CallDetails extracted={extracted} />
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
