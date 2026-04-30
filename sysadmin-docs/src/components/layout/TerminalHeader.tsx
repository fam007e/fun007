import React, { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { prepareWithSegments, layoutWithLines } from '@chenglou/pretext';

export const TerminalHeader: React.FC = () => {
  const [lines, setLines] = useState<string[]>([]);
  const [containerWidth, setContainerWidth] = useState(0);
  const containerRef = useRef<HTMLDivElement>(null);
  
  const fullText = [
    '> Initializing fun007 ecosystem...',
    '> Loading Arch Linux modules [OK]',
    '> Loading Termux automaton [OK]',
    '> Kernel hardening via sysctl [SUCCESS]',
    '> nftables firewall active [SUCCESS]',
    '> System ready. Welcome, Root.'
  ];

  // Mathematically update width for pretext calculations
  useEffect(() => {
    const handleResize = () => {
      if (containerRef.current) {
        setContainerWidth(containerRef.current.offsetWidth);
      }
    };
    
    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  useEffect(() => {
    let currentLine = 0;
    const interval = setInterval(() => {
      if (currentLine < fullText.length) {
        setLines(prev => [...prev, fullText[currentLine]]);
        currentLine++;
      } else {
        clearInterval(interval);
      }
    }, 400);
    return () => clearInterval(interval);
  }, []);

  // Pretext Layout Logic with Fallback
  const renderLine = (text: string, index: number) => {
    // Safety guard for initial render or small widths
    if (containerWidth < 100) {
      return (
        <div key={index} className="terminal-line">
          <span className="terminal-prompt">➜</span> {text}
        </div>
      );
    }

    try {
      // 1. Prepare text with segments (Font: 14px JetBrains Mono)
      const prepared = prepareWithSegments(text, '14px "JetBrains Mono", monospace');
      
      // 2. Compute Layout (Mathematical line breaks)
      const maxWidth = Math.max(containerWidth - 60, 100);
      const { lines: computedLines } = layoutWithLines(prepared, maxWidth, 20);

      if (!computedLines || computedLines.length === 0) {
        throw new Error("Pretext layout returned empty lines");
      }

      return (
        <div key={index} className="terminal-group">
          {computedLines.map((line: any, i: number) => (
            <motion.div 
              key={`${index}-${i}`}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              className="terminal-line"
            >
              {i === 0 && <span className="terminal-prompt">➜</span>}
              {line.text}
            </motion.div>
          ))}
        </div>
      );
    } catch (error) {
      // Pedagogical Fallback: If Pretext fails, use standard DOM rendering
      return (
        <div key={index} className="terminal-line">
          <span className="terminal-prompt">➜</span> {text}
        </div>
      );
    }
  };

  return (
    <div className="terminal-full-width" ref={containerRef}>
      <div className="terminal-container">
        <div className="terminal-bar">
          <div className="terminal-dot red" />
          <div className="terminal-dot yellow" />
          <div className="terminal-dot green" />
          <span className="terminal-title">bash — fun007</span>
        </div>
        <div className="terminal-body">
          {lines.map((line, i) => renderLine(line, i))}
          <div className="cursor-blink" />
        </div>
      </div>

      <style>{`
        .terminal-full-width {
          width: 100%;
          background: #000;
          border-top: 1px solid var(--border-color);
          border-bottom: 1px solid var(--border-color);
          box-shadow: 0 10px 30px rgba(0,0,0,0.5);
          margin-bottom: 80px;
        }
        .terminal-container {
          max-width: 1200px;
          margin: 0 auto;
        }
        .terminal-bar {
          background: #0f172a;
          padding: 10px 24px;
          display: flex;
          align-items: center;
          gap: 8px;
          border-bottom: 1px solid var(--border-color);
        }
        .terminal-dot {
          width: 10px;
          height: 10px;
          border-radius: 50%;
        }
        .red { background: var(--terminal-red); }
        .yellow { background: var(--terminal-yellow); }
        .green { background: var(--terminal-green); }
        .terminal-title {
          margin-left: auto;
          margin-right: auto;
          font-size: 0.75rem;
          color: var(--text-secondary);
          font-family: var(--font-mono);
          letter-spacing: 1px;
        }
        .terminal-body {
          padding: 24px;
          min-height: 200px;
          font-family: var(--font-mono);
          font-size: 0.9rem;
          color: var(--terminal-green);
        }
        .terminal-group {
          margin-bottom: 6px;
        }
        .terminal-line {
          display: flex;
          align-items: center;
          gap: 12px;
          line-height: 1.5;
        }
        .terminal-prompt {
          color: var(--accent-cyan);
        }
        .cursor-blink {
          width: 8px;
          height: 1.2em;
          background: var(--terminal-green);
          display: inline-block;
          animation: blink 1s infinite;
          vertical-align: middle;
          margin-left: 4px;
        }
        @keyframes blink {
          50% { opacity: 0; }
        }
      `}</style>
    </div>
  );
};
