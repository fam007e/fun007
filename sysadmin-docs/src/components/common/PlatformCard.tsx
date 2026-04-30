import React from 'react';
import { motion } from 'framer-motion';
import type { LucideIcon } from 'lucide-react';

interface PlatformCardProps {
  title: string;
  description: string;
  icon: LucideIcon;
  color: 'cyan' | 'lime';
  onClick?: () => void;
}

export const PlatformCard: React.FC<PlatformCardProps> = ({ title, description, icon: Icon, color, onClick }) => {
  const accentColor = color === 'cyan' ? 'var(--accent-cyan)' : 'var(--accent-lime)';
  const dimColor = color === 'cyan' ? 'var(--accent-cyan-dim)' : 'var(--accent-lime-dim)';

  return (
    <motion.div 
      whileHover={{ y: -5, scale: 1.02 }}
      className="platform-card"
      style={{ '--card-accent': accentColor, '--card-dim': dimColor } as any}
      onClick={onClick}
    >
      <div className="card-icon">
        <Icon size={32} color={accentColor} />
      </div>
      <h3>{title}</h3>
      <p>{description}</p>
      <div className="card-footer">
        <span>Explore Logic →</span>
      </div>

      <style>{`
        .platform-card {
          background: var(--bg-secondary);
          border: 1px solid var(--border-color);
          border-radius: 12px;
          padding: 24px;
          cursor: pointer;
          transition: border-color 0.3s ease;
          position: relative;
          overflow: hidden;
        }
        .platform-card:hover {
          border-color: var(--card-accent);
        }
        .platform-card::after {
          content: '';
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: radial-gradient(circle at top right, var(--card-dim), transparent 60%);
          pointer-events: none;
        }
        .card-icon {
          margin-bottom: 16px;
        }
        h3 {
          font-size: 1.5rem;
          margin-bottom: 8px;
          color: var(--text-primary);
        }
        p {
          color: var(--text-secondary);
          font-size: 0.95rem;
          margin-bottom: 24px;
        }
        .card-footer {
          font-family: var(--font-mono);
          font-size: 0.8rem;
          color: var(--card-accent);
          text-transform: uppercase;
          letter-spacing: 1px;
        }
      `}</style>
    </motion.div>
  );
};
