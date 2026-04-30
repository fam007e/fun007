import { motion } from 'framer-motion';
import { Monitor, Cpu, ShieldCheck, Zap, BookOpen, Terminal, Code, Copy } from 'lucide-react';
import { TerminalHeader } from './components/layout/TerminalHeader';
import { PlatformCard } from './components/common/PlatformCard';
import { PhaseStepper } from './components/features/PhaseStepper';
import { CodeBlock } from './components/features/CodeBlock';

const archPhases = [
  {
    title: "Hardware Detection & Encryption",
    description: "Pre-flight checks followed by LUKS2 volume creation.",
    details: ["TPM2/FIDO2 hardware verification", "BTRFS-on-LUKS performance tuning"]
  },
  {
    title: "BTRFS Subvolume Architecture",
    description: "Strategic subvolume layout for Timeshift & swap optimization.",
    details: ["Dedicated @swap subvolume with COW disabled", "@home, @var, @tmp isolation"]
  },
  {
    title: "Base Bootstrap & Handover",
    description: "System base installation followed by fun007 zsh integration.",
    details: ["controllable swap sizing", "automated ecosystem handover"]
  }
];

const zshPhases = [
  {
    title: "Essential Bootstrap",
    description: "Installing core build tools and git.",
    details: ["base-devel meta-package installation"]
  },
  {
    title: "AUR Helper Orchestration",
    description: "Intelligent selection and setup of Yay or Paru.",
    details: ["Automatic fallback if build fails"]
  },
  {
    title: "Bulk Dependency Management",
    description: "Mass installation of 30+ core productivity tools.",
    details: ["Zoxide, Eza, Bat, Fzf integration"]
  },
  {
    title: "Version & Plugin Managers",
    description: "Deploying SDKMAN and Zinit for seamless workflow.",
    details: ["Zero-config plugin initialization"]
  }
];

const termuxPhases = [
  {
    title: "Environment Initialization",
    description: "Setting up storage access and core package managers.",
    details: ["termux-setup-storage validation", "pkg/apt repository synchronization"]
  },
  {
    title: "Toolchain Deployment",
    description: "Automated installation of CLI tools and compilers.",
    details: ["Python/Node/Go environment setup", "Nerd Font & Powerline integration"]
  },
  {
    title: "Post-Install Hardening",
    description: "Configuring security defaults and dotfile symlinks.",
    details: ["Automatic SSH hardening", "fun007 repo cloning & symlinking"]
  }
];

function App() {
  const scrollTo = (id: string) => {
    const element = document.getElementById(id);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' });
    }
  };

  return (
    <div className="app-container">
      <nav className="navbar">
        <div className="nav-brand">fun007 <span className="text-dim">/</span> SysAdmin</div>
        <div className="nav-links">
          <a href="#gallery" onClick={(e) => { e.preventDefault(); scrollTo('gallery'); }}>Gallery</a>
          <a href="#arch" onClick={(e) => { e.preventDefault(); scrollTo('arch'); }}>Arch</a>
          <a href="#termux" onClick={(e) => { e.preventDefault(); scrollTo('termux'); }}>Termux</a>
          <a href="https://github.com/fam007e/fun007" target="_blank" className="btn-git">
            <Code size={14} style={{ marginRight: '8px', verticalAlign: 'middle' }} /> GitHub
          </a>
        </div>
      </nav>

      <header className="hero">
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          className="hero-badge"
        >
          <Terminal size={14} /> 2026 Edition Ready
        </motion.div>
        <motion.h1 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="hero-title"
        >
          Automated <span className="text-cyan">Arch</span> & <span className="text-lime">Termux</span>
        </motion.h1>
        <motion.p 
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="hero-subtitle"
        >
          The definitive system-admin suite for power users. 
          Hardened by design, documented with pedagogical precision.
        </motion.p>
        <TerminalHeader />
      </header>

      <main className="content">
        <section className="platform-grid">
          <PlatformCard 
            title="Arch Linux"
            description="Modular installer with LUKS/BTRFS and Tier-2 mirror hardening logic."
            icon={Cpu}
            color="cyan"
            onClick={() => scrollTo('arch')}
          />
          <PlatformCard 
            title="Termux"
            description="Complete Android system-admin automation for mobile power users."
            icon={Monitor}
            color="lime"
            onClick={() => scrollTo('termux')}
          />
        </section>

        <section className="one-liner-section">
          <div className="one-liner-content">
            <div className="one-liner-header">
              <Zap size={20} className="text-cyan" />
              <h3>Unified Bootstrap</h3>
            </div>
            <p>A single command to deploy any role: Fresh Install, Hardened Mirror, or Desktop Environment. Autodetects Arch or Termux.</p>
            <div className="command-box">
              <code className="command-text">curl -fsSL https://fam007e.github.io/fun007/bootstrap.sh | bash</code>
              <button 
                onClick={() => navigator.clipboard.writeText('curl -fsSL https://fam007e.github.io/fun007/bootstrap.sh | bash')}
                className="copy-btn-large"
              >
                <Copy size={18} />
              </button>
            </div>
          </div>
        </section>

        <style>{`
          .one-liner-section {
            margin-bottom: 80px;
            background: linear-gradient(90deg, var(--accent-cyan-dim), var(--accent-lime-dim));
            padding: 2px;
            border-radius: 12px;
          }
          .one-liner-content {
            background: var(--bg-primary);
            padding: 32px;
            border-radius: 11px;
            text-align: center;
          }
          .one-liner-header {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 12px;
            margin-bottom: 12px;
          }
          .one-liner-header h3 {
            font-size: 1.5rem;
            letter-spacing: -0.5px;
          }
          .one-liner-content p {
            color: var(--text-secondary);
            margin-bottom: 24px;
          }
          .command-box {
            background: #000;
            border: 1px solid var(--border-color);
            padding: 16px 24px;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 20px;
            max-width: 800px;
            margin: 0 auto;
          }
          .command-text {
            font-family: var(--font-mono);
            color: var(--accent-cyan);
            font-size: 1rem;
            white-space: nowrap;
            overflow-x: auto;
          }
          .copy-btn-large {
            background: var(--bg-tertiary);
            border: 1px solid var(--border-color);
            color: var(--text-primary);
            padding: 8px;
            border-radius: 6px;
            cursor: pointer;
            transition: all 0.2s;
          }
          .copy-btn-large:hover {
            background: var(--border-color);
            border-color: var(--accent-cyan);
          }
        `}</style>

        <section id="arch" className="section">
          <div className="section-header">
            <h2 className="section-title"><span className="text-cyan">Arch</span> Installation Logic</h2>
            <p className="section-desc">A deep dive into the BTRFS-safe installer architecture.</p>
          </div>
          <div className="grid-2col">
            <PhaseStepper phases={archPhases} color="cyan" />
            <div className="content-prose">
              <div className="pro-tip">
                <BookOpen size={20} className="text-cyan" />
                <div>
                  <strong>Pedagogical Insight: BTRFS Swap</strong>
                  <p>Standard swapfiles on BTRFS cause performance fragmentation. We solve this by creating a dedicated @swap subvolume and disabling COW via chattr +C before file creation.</p>
                </div>
              </div>
              <CodeBlock 
                filename="archinstall_interactive.sh"
                language="bash"
                code={`# Create @swap subvolume - isolated from snapshots
btrfs subvolume create /mnt/@swap
chattr +C /mnt/swap
dd if=/dev/zero of=/mnt/swap/swapfile bs=1M ...`}
                philosophy="Contiguous allocation (dd) is required because fallocate creates extents that the kernel rejects on BTRFS."
              />
            </div>
          </div>
        </section>

        <section id="termux" className="section">
          <div className="section-header">
            <h2 className="section-title"><span className="text-lime">Termux</span> Automation</h2>
            <p className="section-desc">Transforming Android into a professional SysAdmin environment.</p>
          </div>
          <div className="grid-2col">
            <PhaseStepper phases={termuxPhases} color="lime" />
            <div className="content-prose">
              <div className="pro-tip" style={{ borderColor: 'var(--accent-lime)', background: 'var(--accent-lime-dim)' }}>
                <Monitor size={20} className="text-lime" />
                <div>
                  <strong>Pedagogical Insight: Mobile Persistence</strong>
                  <p>Termux setup requires careful handling of Android's scoped storage. The automaton ensures proper symlinking to internal storage so dotfiles remain accessible and persistent.</p>
                </div>
              </div>
              <CodeBlock 
                filename="Termux_PostInstall_automaton.sh"
                language="bash"
                code={`# Initialize core environment
termux-setup-storage
pkg update && pkg upgrade -y
pkg install zsh curl git ...`}
                philosophy="The automaton bridges the gap between a mobile shell and a full Linux environment with zero user friction."
              />
            </div>
          </div>
        </section>

        <section id="gallery" className="gallery-section">
          <div className="section-header text-center">
            <h2 className="section-title">The <span className="text-cyan">Config</span> Gallery</h2>
            <p className="section-desc">Exhibiting the sanitized core of the fun007 environment.</p>
          </div>
          
          <div className="config-showcase">
             <div className="feature-item">
              <div className="feature-header">
                <Zap className="text-cyan" />
                <h4>Zsh & Shell Logic</h4>
              </div>
              <p>Productivity-first shell with deep integration for torrents, security, and environment management.</p>
              <CodeBlock 
                filename="zshrc_SAFE"
                language="bash"
                code={`# TorrentBD RSS news & download integration
torrentbd_news() {
  local rss_url="<INSERT RSS FEED URL HERE>"
  # ... automated parsing and qBittorrent handover
}

# user-specific bins to path array
path=(
  "$GOBIN"
  "$ANDROID_HOME/platform-tools"
  "$path[@]"
)`}
                philosophy="By using the 'path' array instead of 'PATH' string, Zsh handles uniqueness and precedence automatically, preventing path pollution."
              />
              <PhaseStepper phases={zshPhases} color="cyan" />
            </div>

            <div className="feature-item">
              <div className="feature-header">
                <ShieldCheck className="text-lime" />
                <h4>Window Management</h4>
              </div>
              <p>An optimized Wayland environment (Hyprland) focused on performance and seamless workspace transitions.</p>
              <CodeBlock 
                filename="hyprland.conf"
                language="bash"
                code={`# Performance & Window Swallowing
misc {
  disable_hyprland_logo = true
  enable_swallow = true
  swallow_regex = ^(kitty)$
}

# Strategic Gaps & Borders
general {
  gaps_in=5
  gaps_out=5
  border_size=0
}`}
                philosophy="Window swallowing prevents terminal clutter by repurposing the current window for launched graphical applications."
              />
              <div className="pro-tip" style={{ borderColor: 'var(--accent-lime)', background: 'var(--accent-lime-dim)' }}>
                <Monitor size={20} className="text-lime" />
                <div>
                  <strong>Pedagogical Insight: Security Hardening</strong>
                  <p>Our mirror hardening logic (nftables/sshguard) uses escalating bans to protect infrastructure from brute-force attempts while remaining transparent to legitimate traffic.</p>
                </div>
              </div>
              <CodeBlock 
                filename="arch-mirror-hardened.sh"
                language="bash"
                code={`# escalting ban duration: 2m, ~13m, ~1.5h...
BLOCK_TIME=120
THRESHOLD=40
BACKEND="/usr/lib/sshguard/sshg-fw-nft-sets"`}
                philosophy="Combining nftables sets with sshguard allows for kernel-level blocking, which is significantly more efficient than userspace filtering."
              />
            </div>
          </div>
        </section>
      </main>

      <footer className="footer">
        <div className="footer-content">
          <p>© 2026 fun007 Ecosystem</p>
          <div className="footer-links">
            <a href="https://github.com/fam007e/fun007">Source Code</a>
            <a href="#">Privacy Sanitization Policy</a>
          </div>
        </div>
      </footer>

      <style>{`
        .feature-header {
          display: flex;
          align-items: center;
          gap: 12px;
          margin-bottom: 8px;
        }
        .app-container {
          width: 100%;
          margin: 0;
          padding: 0;
        }
        .navbar {
          display: flex;
          flex-direction: column;
          gap: 1.5rem;
          justify-content: space-between;
          align-items: center;
          padding: 24px clamp(1rem, 5vw, 4rem);
          border-bottom: 1px solid var(--border-color);
          width: 100%;
        }
        @media (min-width: 640px) {
          .navbar {
            flex-direction: row;
          }
        }
        .nav-brand {
          font-family: var(--font-mono);
          font-weight: 700;
          font-size: clamp(1.1rem, 2.5vw, 1.4rem);
          letter-spacing: -1px;
        }
        .nav-links {
          display: flex;
          gap: clamp(1.5rem, 4vw, 3rem);
          align-items: center;
          flex-wrap: wrap;
          justify-content: center;
        }
        .nav-links a {
          color: var(--text-secondary);
          text-decoration: none;
          font-size: 0.95rem;
          transition: color 0.3s;
        }
        .hero {
          width: 100%;
          padding: clamp(60px, 12vw, 120px) clamp(1rem, 5vw, 4rem) 0;
          text-align: center;
        }
        .hero-title {
          font-size: clamp(2.2rem, 10vw, 4.5rem);
          font-weight: 800;
          margin-bottom: 16px;
          letter-spacing: -0.04em;
          line-height: 1.05;
        }
        .hero-subtitle {
          color: var(--text-secondary);
          max-width: 600px;
          margin: 0 auto clamp(30px, 8vw, 60px);
          font-size: clamp(0.95rem, 2.5vw, 1.1rem);
        }
        .content {
          padding: 0 clamp(1rem, 5vw, 4rem);
          max-width: 1800px;
          margin: 0 auto;
        }
        .platform-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(min(100%, 320px), 1fr));
          gap: 2rem;
          margin-bottom: clamp(60px, 12vw, 120px);
        }
        .section {
          padding: clamp(40px, 8vw, 80px) 0;
          border-top: 1px solid var(--border-color);
        }
        .grid-2col {
          display: grid;
          grid-template-columns: 1fr;
          gap: 3rem;
        }
        @media (min-width: 1024px) {
          .grid-2col {
            grid-template-columns: 1fr 1fr;
          }
        }
        .one-liner-content {
          background: var(--bg-primary);
          padding: clamp(1.5rem, 5vw, 2.5rem);
          border-radius: 11px;
          text-align: center;
        }
        .command-box {
          background: #000;
          border: 1px solid var(--border-color);
          padding: clamp(0.75rem, 3vw, 1.25rem);
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 1rem;
          max-width: 800px;
          margin: 0 auto;
          width: 100%;
        }
        .command-text {
          font-family: var(--font-mono);
          color: var(--accent-cyan);
          font-size: clamp(0.75rem, 2vw, 0.95rem);
          white-space: nowrap;
          overflow-x: auto;
          scrollbar-width: none;
        }
        .command-text::-webkit-scrollbar { display: none; }

        .gallery-section {
          padding: clamp(60px, 12vw, 120px) 0;
          background: radial-gradient(circle at center, #0f172a 0%, #020617 100%);
        }
        .config-showcase {
          display: grid;
          grid-template-columns: 1fr;
          gap: clamp(3rem, 8vw, 5rem);
        }
        @media (min-width: 1024px) {
          .config-showcase {
            grid-template-columns: 0.9fr 1.1fr;
            gap: 2.5rem;
          }
        }
        .footer-content {
          display: flex;
          flex-direction: column;
          gap: 1.5rem;
          justify-content: space-between;
          align-items: center;
          color: var(--text-dim);
          font-size: 0.85rem;
        }
        @media (min-width: 640px) {
          .footer-content {
            flex-direction: row;
          }
        }

        .footer-links {
          display: flex;
          gap: 24px;
        }
        .footer-links a {
          color: var(--text-dim);
          text-decoration: none;
        }
        .footer-links a:hover {
          color: var(--text-secondary);
        }
      `}</style>
    </div>
  );
}

export default App;
