import { useRef, useEffect, useState } from 'react';

export default function AnimatedCard({ children, className = '' }) {
  const [entered, setEntered] = useState(false);
  const ref = useRef(false);

  useEffect(() => {
    if (!ref.current) {
      ref.current = true;
      setEntered(true);
    }
  }, []);

  return (
    <div className={`card ${entered ? 'card-enter' : ''} ${className}`}>
      {children}
    </div>
  );
}
