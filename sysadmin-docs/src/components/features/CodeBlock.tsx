import React, { useState } from 'react';
import { Copy, Check, Info } from 'lucide-react';

interface CodeBlockProps {
  code: string;
  language: string;
  filename?: string;
  philosophy?: string;
}

export const CodeBlock: React.FC<CodeBlockProps> = ({ code, language, filename, philosophy }) => {
  const [copied, setCopied] = useState(false);

  const copyToClipboard = () => {
    navigator.clipboard.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="code-container">
      {filename && (
        <div className="code-header">
          <span className="code-filename">{filename}</span>
          <button onClick={copyToClipboard} className="copy-btn">
            {copied ? <Check size={14} color="var(--terminal-green)" /> : <Copy size={14} />}
          </button>
        </div>
      )}
      <div className="code-wrapper">
        <pre className={`language-${language}`}>
          <code>{code}</code>
        </pre>
        {philosophy && (
          <div className="philosophy-sidebar">
            <div className="philosophy-tag">
              <Info size={12} />
              <span>Philosophy</span>
            </div>
            <p className="philosophy-text">{philosophy}</p>
          </div>
        )}
      </div>

      <style>{`
        .code-container {
          background: #000;
          border: 1px solid var(--border-color);
          border-radius: 8px;
          margin: 1.5rem 0;
          overflow: hidden;
        }
        .code-header {
          background: var(--bg-secondary);
          padding: 8px 16px;
          display: flex;
          justify-content: space-between;
          align-items: center;
          border-bottom: 1px solid var(--border-color);
        }
        .code-filename {
          font-family: var(--font-mono);
          font-size: 0.75rem;
          color: var(--text-secondary);
        }
        .copy-btn {
          background: transparent;
          border: none;
          color: var(--text-dim);
          cursor: pointer;
          transition: color 0.2s;
        }
        .copy-btn:hover {
          color: var(--text-primary);
        }
        .code-wrapper {
          display: grid;
          grid-template-columns: 1fr;
        }
        @media (min-width: 1024px) {
          .code-wrapper {
            grid-template-columns: 1fr 250px;
          }
        }
        pre {
          padding: 16px;
          margin: 0;
          overflow-x: auto;
          font-size: 0.85rem;
          color: #d1d5db;
        }
        .philosophy-sidebar {
          background: rgba(30, 41, 59, 0.5);
          padding: 16px;
          border-left: 1px solid var(--border-color);
        }
        .philosophy-tag {
          display: flex;
          align-items: center;
          gap: 6px;
          font-family: var(--font-mono);
          font-size: 0.65rem;
          text-transform: uppercase;
          color: var(--accent-cyan);
          margin-bottom: 8px;
        }
        .philosophy-text {
          font-size: 0.8rem;
          color: var(--text-secondary);
          line-height: 1.4;
        }
      `}</style>
    </div>
  );
};
