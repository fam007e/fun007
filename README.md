# fun007

**A Professional Collection of Systems Engineering, Scientific Visualization, and Utility Scripts.**

`fun007` is a curated repository of high-performance utilities, system automation scripts, and scientific visualization modules. It serves as a centralized toolkit for Linux system administration, materials science modeling, cryptographic security, and efficient file management.

## 📂 Project Structure

```
fun007/
├── system-admin/     # System Administration & Configuration
├── scientific/       # Scientific Visualization & Computing
├── security/         # Security & Cryptography
├── media-tools/      # Media & File Operations
└── dev-tools/        # AI & Development Tools
```

---

### 🖥️ System Administration & Configuration

| Tool                                             | Description                                                                                                                                                                                                          |
| :----------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**arch-install**](system-admin/arch-install/)   | Enterprise-grade automation for Arch Linux deployment. Features multi-drive support (SSD/HDD), Btrfs encryption with subvolumes, CPU microcode detection, and secure drive wiping.                                   |
| [**termux-setup**](system-admin/termux-setup/)   | A comprehensive `bash` automation suite for Android/Termux environments. Handles SSH key generation (Ed25519), GitHub integration, Nerd Font installation, and shell environment (Zsh/Starship/Neovim) provisioning. |
| [**dotfiles**](system-admin/dotfiles/)           | Production-ready configuration files for high-efficiency workflows. Includes optimized setups for **Hyprland**, **Neovim**, **Alacritty**, **Kitty**, and **Zsh**.                                                   |
| [**mtu-optimizer**](system-admin/mtu-optimizer/) | Network utility to calculate and apply the optimal Maximum Transmission Unit (MTU) size to prevent packet fragmentation and improve throughput.                                                                      |
| [**iso-verifier**](system-admin/iso-verifier/)   | Security script to verify the integrity of ISO images against checksums, ensuring safe OS installations.                                                                                                             |

### 🔭 Scientific Visualization & Computing

| Tool                                           | Description                                                                                                                                                                                                                           |
| :--------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [**blackhole-viz**](scientific/blackhole-viz/) | A Python-based general relativity visualization engine. Generates 2D, 3D, and 4D representations of spacetime concepts, including **Schwarzschild/Kerr metrics**, **Penrose diagrams**, **light cones**, and **wormhole embeddings**. |
| [**lattice-viz**](scientific/lattice-viz/)     | Materials science module for visualizing BCC (Body-Centered Cubic) and FCC (Face-Centered Cubic) crystal lattices. Includes functionality to calculate the **Schmid factor** for slip system analysis.                                |
| [**buffon-needle**](scientific/buffon-needle/) | Monte Carlo simulation of Buffon's Needle experiment to estimate π with multiple RNG support and convergence visualization.                                                                                                           |
| [**pi-estimator**](scientific/pi-estimator/)   | High-performance parallel computing demonstration. Estimates the value of π using a multi-processed Monte Carlo simulation technique.                                                                                                 |

### 🔐 Security & Cryptography

| Tool                                         | Description                                                                                                                                                             |
| :------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [**password-gen**](security/password-gen/)   | Cryptographically secure password generator utilizing Python's `secrets` module. Enforces minimum security standards (12+ chars) and calculates real-time entropy bits. |
| [**wordlist-gen**](security/wordlist-gen/)   | Permutation-based wordlist generator. Creates comprehensive combination lists from input strings for dictionary attack testing or recovery.                             |
| [**rand-name-gen**](security/rand-name-gen/) | Random name generator for testing and anonymization purposes.                                                                                                           |

### 📄 Media & File Operations

| Tool                                                    | Description                                                                                                     |
| :------------------------------------------------------ | :-------------------------------------------------------------------------------------------------------------- |
| [**pdf-scanner**](media-tools/pdf-scanner/)             | Extracts and locates keywords within PDF documents.                                                             |
| [**pdf-splitter**](media-tools/pdf-splitter/)           | Segments large PDFs into individual files.                                                                      |
| [**text-to-pdf**](media-tools/text-to-pdf/)             | Converts plain text streams into formatted PDF documents.                                                       |
| [**pdf-to-audio**](media-tools/pdf-to-audio/)           | Converts document text to MP3 audio for accessibility.                                                          |
| [**youtube-dl**](media-tools/youtube-dl/)               | CLI wrapper for `pytube` to fetch the highest resolution video streams from YouTube.                            |
| [**wallpaper-cleaner**](media-tools/wallpaper-cleaner/) | Privacy and organization tool for image collections. Filters images by resolution and strips all EXIF/metadata. |

### 🤖 AI & Development Tools

| Tool                                              | Description                                                                                                                     |
| :------------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------ |
| [**openai-chat**](dev-tools/openai-chat/)         | A lightweight, C-based CLI client for the OpenAI API (`gpt-3.5-turbo`). Demonstrates raw HTTP networking and JSON parsing in C. |
| [**python-keywords**](dev-tools/python-keywords/) | Developer utility to quickly inspect reserved Python keywords and syntax definitions.                                           |
| [**grade-calc**](dev-tools/grade-calc/)           | Lenient grade calculator with automatic rounding for borderline percentages.                                                    |
| [**file-cleaner**](dev-tools/file-cleaner/)       | Interactive CLI utility for targeted file deletion.                                                                             |

---

## 🚀 Usage & Installation

Since `fun007` is a collection of independent utilities, dependencies vary by tool. Most tools are written in **Python 3** or **Bash**.

### General Setup
Clone the repository to your local machine:

```bash
git clone https://github.com/fam007e/fun007.git
cd fun007
```

### Example: Running the Black Hole Visualizer
```bash
cd scientific/blackhole-viz
pip install -r requirements.txt
python blackholeplot.py
```

### Example: Termux Setup
```bash
cd system-admin/termux-setup
bash Termux_PostInstall_automaton.sh
```

## 🤝 Contributing

Contributions are welcome from the community. To contribute:
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/NewTool`).
3. Commit your changes with conventional messages.
4. Push to the branch and open a Pull Request.

## 📄 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.
