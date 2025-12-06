# fun007

**A Professional Collection of Systems Engineering, Scientific Visualization, and Utility Scripts.**

`fun007` is a curated repository of high-performance utilities, system automation scripts, and scientific visualization modules. It serves as a centralized toolkit for Linux system administration, materials science modeling, cryptographic security, and efficient file management.

## 📂 Project Overview

This repository is organized into specialized domains, reflecting a diverse range of engineering disciplines from general relativity visualizations to automated production environment setups.

### 🖥️ System Administration & Configuration

| Tool | Description |
| :--- | :--- |
| **ArchInstallScript** | Enterprise-grade automation for Arch Linux deployment. Features multi-drive support (SSD/HDD), Btrfs encryption with subvolumes, CPU microcode detection, and secure drive wiping. |
| **Termux Post-Install** | A comprehensive `bash` automation suite for Android/Termux environments. Handles SSH key generation (Ed25519), GitHub integration, Nerd Font installation, and shell environment (Zsh/Starship/Neovim) provisioning. |
| **configs** | Production-ready configuration files ("dotfiles") for high-efficiency workflows. Includes optimized setups for **Hyprland**, **Neovim**, **Alacritty**, **Kitty**, and **Zsh**. |
| **MTU_size_optimiser** | Network utility to calculate and apply the optimal Maximum Transmission Unit (MTU) size to prevent packet fragmentation and improve throughput. |
| **ISO_verifier** | Security script to verify the integrity of ISO images against checksums, ensuring safe OS installations. |

### 🔭 Scientific Visualization & Computing

| Tool | Description |
| :--- | :--- |
| **BlackHolePLT** | A Python-based general relativity visualization engine. Generates 2D, 3D, and 4D representations of spacetime concepts, including **Schwarzschild/Kerr metrics**, **Penrose diagrams**, **light cones**, and **wormhole embeddings**. |
| **Lattice_visualization** | Materials science module for visualizing BCC (Body-Centered Cubic) and FCC (Face-Centered Cubic) crystal lattices. Includes functionality to calculate the **Schmid factor** for slip system analysis. |
| **PI** | High-performance parallel computing demonstration. Estimates the value of $\pi$ using a multi-processed Monte Carlo simulation technique. |

### 🔐 Security & Cryptography

| Tool | Description |
| :--- | :--- |
| **Passwd_Generator** | Cryptographically secure password generator utilizing Python's `secrets` module. Enforces minimum security standards (12+ chars) and calculates real-time entropy bits. |
| **Wordlister** | Permutation-based wordlist generator. Creates comprehensive combination lists from input strings for dictionary attack testing or recovery. |
| **ISO_verifier** | (See System Admin) Ensures binary integrity of downloaded media. |

### 📄 Media & File Operations

| Tool | Description |
| :--- | :--- |
| **PDF Suite** | A collection of tools for PDF manipulation: <br>• **PDF_scanner**: Extracts and locates keywords within documents.<br>• **PDF_splitter**: Segments large PDFs into individual files.<br>• **Text2PDF**: Converts plain text streams into formatted PDF documents.<br>• **PDF2MP3**: Converts document text to audio for accessibility. |
| **Wallpaper_MetaCleaner** | Privacy and organization tool for image collections. Filters images by resolution (deleting thumbnails) and strips all EXIF/metadata using `exiftool`. |
| **Youtubedownloader** | CLI wrapper for `pytube` to fetch the highest resolution video streams from YouTube. |
| **DWNFDCleaner** | Interactive CLI utility for targeted file deletion (despite the name implying bulk directory cleaning). |

### 🤖 AI & Development

| Tool | Description |
| :--- | :--- |
| **OPAI_CHAT** | A lightweight, C-based CLI client for the OpenAI API (`gpt-3.5-turbo`). Demonstrates raw HTTP networking and JSON parsing in C. |
| **Python_kws** | Developer utility to quickly inspect reserved Python keywords and syntax definitions. |

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
cd BlackHolePLT
pip install -r requirements.txt  # (If applicable, or install matplotlib/numpy)
python blackholeplot_v2.py
```

### Example: Termux Setup
```bash
cd Termux_postinstallconfig_script
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
