# fun007

**A Professional Collection of Systems Engineering, Scientific Visualization, and Utility Scripts.**

`fun007` is a curated repository of high-performance utilities, system automation scripts, and scientific visualization modules. It serves as a centralized toolkit for Linux system administration, materials science modeling, cryptographic security, and efficient file management.

## 📂 Project Structure

```
fun007/
├── system-admin/     # OS Automation, Dotfiles, & Network Utils
├── scientific/       # General Relativity & Materials Science Viz
├── security/         # Cryptography & Password Security
├── media-tools/      # PDF Operations & Media Fetching
└── dev-tools/        # C/Python Development Utilities
```

---

### 🖥️ System Administration & Configuration

| Tool                                             | Description                                                                                                                                                                                                          |
| :----------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**arch-install**](system-admin/arch-install/)   | Modular Arch Linux installer focusing on **LUKS-on-Btrfs** with Timeshift subvolume mapping. Features hardware-aware GPU driver injection and an automated handover to the `fun007` bootstrap.                         |
| [**termux-setup**](system-admin/termux-setup/)   | Advanced Android/Termux automation. Features dynamic Nerd Font fetching via GitHub API, SSH/GitHub identity provisioning, and automated synchronization with the core `fun007` dotfiles.                            |
| [**dotfiles**](system-admin/dotfiles/)           | The "Source of Truth" for system configurations. Modular **Bash** and **Zsh** setups optimized for both Desktop and Termux, featuring safe directory navigation and extensive tool aliasing.                          |
| [**mtu-optimizer**](system-admin/mtu-optimizer/) | Network utility to calculate and apply the optimal Maximum Transmission Unit (MTU) size to prevent packet fragmentation and improve throughput.                                                                      |
| [**iso-verifier**](system-admin/iso-verifier/)   | Security script to verify the integrity of ISO images against checksums, ensuring safe OS installations.                                                                                                             |

### 🔭 Scientific Visualization & Computing

| Tool                                           | Description                                                                                                                                                                                                                           |
| :--------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [**blackhole-viz**](scientific/blackhole-viz/) | A Python-based general relativity visualization engine. Generates 2D, 3D, and 4D representations of spacetime concepts, including **Schwarzschild/Kerr metrics**, **Penrose diagrams**, and **light cones**.                          |
| [**lattice-viz**](scientific/lattice-viz/)     | Materials science module for visualizing BCC and FCC crystal lattices. Includes functionality to calculate the **Schmid factor** for slip system analysis.                                                                           |
| [**buffon-needle**](scientific/buffon-needle/) | Monte Carlo simulation of Buffon's Needle experiment to estimate π with multiple RNG support and convergence visualization.                                                                                                           |
| [**pi-estimator**](scientific/pi-estimator/)   | High-performance parallel computing demonstration. Estimates the value of π using a multi-processed Monte Carlo simulation technique.                                                                                                 |

### 🔐 Security & Cryptography

| Tool                                         | Description                                                                                                                                                             |
| :------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**password-gen**](security/password-gen/)   | Cryptographically secure password generator utilizing Python's `secrets` module. Enforces minimum security standards (12+ chars) and calculates real-time entropy bits. |
| [**wordlist-gen**](security/wordlist-gen/)   | Permutation-based wordlist generator. Creates comprehensive combination lists from input strings for dictionary attack testing or recovery.                             |
| [**rand-name-gen**](security/rand-name-gen/) | Random name generator for testing and anonymization purposes.                                                                                                           |

---

## 🚀 The "Modular Handover" Architecture

The defining feature of this repository is its **Ecosystem Integration**. 

1.  **Installation**: Run either the `arch-install` or `termux-setup` scripts.
2.  **Handover**: These scripts automatically clone this repository (`fun007`) into your new environment.
3.  **Bootstrap**: The installers delegate final package and shell configuration to `system-admin/dotfiles/zsh/zshrc_pkg_prep.sh`.

This ensures that whether you are on an Arch Linux workstation or an Android device, your environment is **identical, up-to-date, and synchronized.**

### Quick Start (Desktop)
```bash
# Clone and bootstrap your current Arch system
git clone https://github.com/fam007e/fun007.git
cd fun007/system-admin/dotfiles/zsh
bash zshrc_pkg_prep.sh
```

### Quick Start (Termux)
```bash
# Bootstrap a fresh Termux environment
curl -LO https://raw.githubusercontent.com/fam007e/fun007/main/system-admin/termux-setup/Termux_PostInstall_automaton.sh
bash Termux_PostInstall_automaton.sh
```

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
