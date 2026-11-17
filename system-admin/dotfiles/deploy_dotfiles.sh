#!/bin/bash
# ==============================================================================
# fun007 Dotfiles Deployer
# Purpose: Idempotently deploy all fun007 dotfiles onto a (fresh) machine.
# Method:  Symlinks from $HOME into this repo clone — the repo stays the single
#          source of truth, so `git pull` updates configs everywhere.
#
# Usage:
#   ./deploy_dotfiles.sh [--dry-run]
#
# What it does:
#   1. Symlinks every config below into $HOME / $XDG_CONFIG_HOME
#   2. Copies the Meslo Nerd Font into ~/.local/share/fonts
#   3. Installs local.zsh (chmod 600) from the template on first run
#   4. Optionally clones kickstart.nvim and fam007e/DWM (kept in their own
#      repos) and seeds their configs if missing
#
# Safety:
#   - Never touches a real file without backing it up to <target>.bak.<ts>
#   - Existing correct symlinks are left alone (safe to re-run anytime)
#   - --dry-run shows what would happen without changing anything
# ==============================================================================

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOT="$REPO_ROOT/system-admin/dotfiles"
TS="$(date +%Y%m%d_%H%M%S)"

# --- Helpers ------------------------------------------------------------------
log()    { echo -e "\033[1;34m[DEPLOY]\033[0m $1"; }
warn()   { echo -e "\033[1;33m[DEPLOY][WARN]\033[0m $1"; }
run()    { if $DRY_RUN; then echo "  [dry-run] $*"; else "$@"; fi; }

# Link one file or directory.
#   link <repo_path> <target> [dir|file]
link() {
    local src="$1" tgt="$2" kind="${3:-auto}"

    if [[ ! -e "$src" ]]; then
        warn "source missing, skipping: $src"
        return
    fi
    [[ "$kind" == "auto" ]] && kind=$([[ -d "$src" ]] && echo dir || echo file)

    mkdir -p "$(dirname "$tgt")"

    # Already correctly linked — nothing to do (idempotent)
    if [[ -L "$tgt" && "$(readlink -f "$tgt")" == "$(readlink -f "$src")" ]]; then
        log "ok  (linked): $tgt"
        return
    fi

    # Back up any real (non-symlink) target before replacing it
    if [[ -e "$tgt" && ! -L "$tgt" ]]; then
        local bak="${tgt}.bak.${TS}"
        warn "backing up existing $kind: $tgt -> $bak"
        run mv "$tgt" "$bak"
    fi

    run ln -sfn "$src" "$tgt"
    log "linked: $tgt -> $src"
}

# Copy one file (used where symlinks are inappropriate).
copy() {
    local src="$1" tgt="$2"
    [[ ! -e "$src" ]] && { warn "source missing, skipping: $src"; return; }
    mkdir -p "$(dirname "$tgt")"
    if cmp -s "$src" "$tgt" 2>/dev/null; then
        log "ok  (copied): $tgt"
        return
    fi
    if [[ -e "$tgt" && ! -L "$tgt" ]]; then
        warn "backing up existing file: $tgt -> ${tgt}.bak.${TS}"
        run mv "$tgt" "${tgt}.bak.${TS}"
    fi
    run cp "$src" "$tgt"
    log "copied: $tgt"
}

log "Deploying fun007 dotfiles from: $DOT"
$DRY_RUN && log "DRY RUN — no changes will be made"

# --- 1. Top-level home files --------------------------------------------------
# The thin zsh loader; all real config lives in the zsh module dir below.
link "$DOT/zsh/zshrc"         "$HOME/.zshrc"        file
link "$DOT/nanorc_SAFE"       "$HOME/.nanorc"       file

# --- 2. XDG config: whole-directory links (repo dir == live dir) --------------
# zsh module dir: the loader above sources $ZSH_MOD_DIR/*.zsh from here.
# NOTE: local.zsh (secrets, gitignored) is created inside the linked dir by you.
# NOTE: dwm & quickshell are NOT here — they live in the fam007e/DWM repo (§5b).
for name in zsh kitty alacritty rofi fastfetch gtk-3.0 gtk-4.0 picom zed \
            mpv ghostty fish flameshot qBittorrent vifm khal thefuck \
            Thunar qt5ct qt6ct xsettingsd \
            xdg-desktop-portal autostart environment.d systemd nwg-look; do
    link "$DOT/$name" "$HOME/.config/$name" dir
done

# --- 3. XDG config: single-file links -----------------------------------------
link "$DOT/starship.toml"          "$HOME/.config/starship.toml"        file
link "$DOT/tmux.conf"              "$HOME/.config/tmux/tmux.conf"       file
link "$DOT/btop.conf"              "$HOME/.config/btop/btop.conf"       file
link "$DOT/user-dirs.dirs"         "$HOME/.config/user-dirs.dirs"       file
link "$DOT/mimeapps.list"          "$HOME/.config/mimeapps.list"        file
link "$DOT/kdeglobals"             "$HOME/.config/kdeglobals"           file

# --- 4. Fonts (copy — fontconfig scans ~/.local/share/fonts) -------------------
if [[ -f "$DOT/MesloLGSNerdFontMono-Regular.ttf" ]]; then
    copy "$DOT/MesloLGSNerdFontMono-Regular.ttf" \
         "$HOME/.local/share/fonts/MesloLGSNerdFontMono-Regular.ttf"
fi

# --- 5. First-run secrets template (zsh local.zsh) -----------------------------
# ~/.config/zsh is a symlink into the repo; local.zsh lives there, is
# gitignored, and must never be regenerated on an existing machine.
if $DRY_RUN; then
    echo "  [dry-run] ensure local.zsh exists (skip if present)"
elif [[ ! -e "$HOME/.config/zsh/local.zsh" ]]; then
    cp "$DOT/zsh/local.zsh.example" "$HOME/.config/zsh/local.zsh"
    chmod 600 "$HOME/.config/zsh/local.zsh"
    log "created local.zsh from template (chmod 600) — add secrets/overrides there"
else
    log "ok  (present): local.zsh (kept as-is)"
fi

# --- 5b. dwm + quickshell (upstream: fam007e/DWM repo) --------------------------
# The DWM repo's install.sh seeds these (copy-if-missing, preserving local edits),
# and manages dwm secrets/state. We mirror that behaviour: clone the repo if
# absent, then seed only what does not exist yet. Full setup (build dwm, fonts,
# scripts, secrets) = run ~/Github/DWM/install.sh yourself.
DWM_DIR="${DWM_DIR:-$HOME/Github/DWM}"
if [[ ! -e "$DWM_DIR/config" ]]; then
    log "DWM repo not found at $DWM_DIR — cloning (skip via DWM_DIR=... or pre-clone)"
    run git clone --depth 1 https://github.com/fam007e/DWM.git "$DWM_DIR"
fi
if [[ -e "$DWM_DIR/config/quickshell" ]]; then
    if [[ ! -e "$HOME/.config/quickshell" ]]; then
        run cp -r "$DWM_DIR/config/quickshell" "$HOME/.config/quickshell"
        log "seeded ~/.config/quickshell from DWM repo"
    else
        log "ok  (present): ~/.config/quickshell (DWM-managed)"
    fi
fi
if [[ -d "$DWM_DIR/config" ]] && ! $DRY_RUN; then
    mkdir -p "$HOME/.config/dwm/secrets"
    for toml in hotkeys.toml themes.toml window-rules.toml; do
        if [[ ! -f "$HOME/.config/dwm/$toml" && -f "$DWM_DIR/config/$toml" ]]; then
            cp "$DWM_DIR/config/$toml" "$HOME/.config/dwm/$toml"
            log "seeded ~/.config/dwm/$toml from DWM repo"
        else
            log "ok  (present/skip): ~/.config/dwm/$toml"
        fi
    done
    log "note: full dwm setup (build, scripts, secrets) -> run $DWM_DIR/install.sh"
fi

# --- 6. kickstart.nvim (managed in its own repo) -------------------------------
if [[ ! -e "$HOME/.config/nvim" ]]; then
    log "kickstart.nvim not found — cloning (skip if you manage nvim elsewhere)"
    run git clone --depth 1 https://github.com/fam007e/kickstart.nvim.git "$HOME/.config/nvim"
else
    log "ok  (present): ~/.config/nvim (kickstart.nvim, managed separately)"
fi

# --- 7. Refresh font cache -----------------------------------------------------
if command -v fc-cache >/dev/null 2>&1 && ! $DRY_RUN; then
    fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
    log "font cache refreshed"
fi

log "Done. New terminal or 'source ~/.zshrc' to apply."
$DRY_RUN && log "(dry run — nothing was changed)"
