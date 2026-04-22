import { useState, useEffect, useCallback } from 'react';
import './styles/App.css';
import useWebSocket from './hooks/useWebSocket';
import Header from './components/Header';
import CallSimulator from './components/CallSimulator';
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
  const [transcript, setTranscript] = useState('');
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
        setTranscript('');
        setCandidates([]);
        setExtracted(null);
        setCustomer(null);
        setOrders(null);
        setProducts(null);
        setSimilarCases(null);
        break;
      case 'transcript_update':
        setTranscript(msg.full_transcript || '');
        break;
      case 'extraction_update':
        setCandidates(msg.candidates || []);
        setExtracted(msg.extracted || null);
        break;
      case 'customer_match':
        setCustomer(msg.customer);
        setOrders(msg.orders);
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
      />
      <div className="app-body">
        <CallSimulator
          callId={callId}
          playbackProgress={playbackProgress}
          isPlaying={isPlaying}
          onPlaybackStart={handlePlaybackStart}
        />

        {transcript && (
          <div className="card" style={{ marginBottom: 16 }}>
            <div className="card-header">Live Transcript</div>
            <div className="card-body">
              <div className="transcript-box">{transcript}</div>
            </div>
          </div>
        )}

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
    </div>
  );
}

export default App;
