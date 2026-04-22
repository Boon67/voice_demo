import { useEffect, useRef, useState, useCallback } from 'react';

const WS_URL = 'ws://localhost:8080/ws';

export default function useWebSocket() {
  const wsRef = useRef(null);
  const [connected, setConnected] = useState(false);
  const [lastMessage, setLastMessage] = useState(null);
  const reconnectTimer = useRef(null);

  const connect = useCallback(() => {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) return;
    const ws = new WebSocket(WS_URL);
    ws.onopen = () => {
      setConnected(true);
      if (reconnectTimer.current) clearTimeout(reconnectTimer.current);
    };
    ws.onmessage = (e) => {
      try { setLastMessage(JSON.parse(e.data)); } catch {}
    };
    ws.onclose = () => {
      setConnected(false);
      reconnectTimer.current = setTimeout(connect, 3000);
    };
    ws.onerror = () => ws.close();
    wsRef.current = ws;
  }, []);

  useEffect(() => {
    connect();
    return () => {
      if (reconnectTimer.current) clearTimeout(reconnectTimer.current);
      if (wsRef.current) wsRef.current.close();
    };
  }, [connect]);

  const reconnect = useCallback(() => {
    if (wsRef.current) wsRef.current.close();
    setTimeout(connect, 100);
  }, [connect]);

  return { connected, lastMessage, reconnect };
}
