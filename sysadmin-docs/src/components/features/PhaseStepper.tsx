import React from 'react';
import { motion } from 'framer-motion';
import { CheckCircle2 } from 'lucide-react';

interface Phase {
  title: string;
  description: string;
  details: string[];
}

interface PhaseStepperProps {
  phases: Phase[];
  color?: 'cyan' | 'lime';
}

export const PhaseStepper: React.FC<PhaseStepperProps> = ({ phases, color = 'cyan' }) => {
  const accentColor = color === 'cyan' ? 'var(--accent-cyan)' : 'var(--accent-lime)';

  return (
    <div className="stepper-container">
      {phases.map((phase, index) => (
        <div key={index} className="phase-row">
          <div className="phase-indicator">
            <div className="indicator-line-top" style={{ opacity: index === 0 ? 0 : 1 }} />
            <div className="indicator-icon">
              <CheckCircle2 size={24} color={accentColor} />
            </div>
            <div className="indicator-line-bottom" style={{ opacity: index === phases.length - 1 ? 0 : 1 }} />
          </div>
          
          <motion.div 
            initial={{ opacity: 0, x: 20 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            className="phase-content"
          >
            <span className="phase-number" style={{ color: accentColor }}>Phase {index + 1}</span>
            <h4 className="phase-title">{phase.title}</h4>
            <p className="phase-desc">{phase.description}</p>
            <ul className="phase-details">
              {phase.details.map((detail, dIndex) => (
                <li key={dIndex}>{detail}</li>
              ))}
            </ul>
          </motion.div>
        </div>
      ))}

      <style>{`
        .stepper-container {
          padding: 2rem 0;
        }
        .phase-row {
          display: flex;
          gap: 24px;
        }
        .phase-indicator {
          display: flex;
          flex-direction: column;
          align-items: center;
        }
        .indicator-icon {
          background: var(--bg-primary);
          padding: 4px 0;
          z-index: 10;
        }
        .indicator-line-top, .indicator-line-bottom {
          width: 2px;
          flex-grow: 1;
          background: var(--border-color);
        }
        .phase-content {
          padding-bottom: 48px;
          flex: 1;
        }
        .phase-number {
          font-family: var(--font-mono);
          font-size: 0.75rem;
          text-transform: uppercase;
          letter-spacing: 1px;
          display: block;
          margin-bottom: 4px;
        }
        .phase-title {
          font-size: 1.25rem;
          margin-bottom: 8px;
          color: var(--text-primary);
        }
        .phase-desc {
          color: var(--text-secondary);
          font-size: 0.95rem;
          margin-bottom: 12px;
        }
        .phase-details {
          list-style: none;
          display: flex;
          flex-direction: column;
          gap: 6px;
        }
        .phase-details li {
          font-size: 0.85rem;
          color: var(--text-dim);
          position: relative;
          padding-left: 18px;
        }
        .phase-details li::before {
          content: '→';
          position: absolute;
          left: 0;
          color: var(--border-color);
        }
      `}</style>
    </div>
  );
};
