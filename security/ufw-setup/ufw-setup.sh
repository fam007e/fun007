#!/bin/sh
# ufw-setup.sh — idempotent, POSIX-compliant ufw hardening script
# Usage: sudo sh ufw-setup.sh
# Edit the RULES section below to match your machine before running.

set -eu

# ─── CONFIG ───────────────────────────────────────────────────────────────────

DEFAULT_INCOMING="deny"
DEFAULT_OUTGOING="allow"

# Rules format: "port/proto:source"
# source "any"            → anywhere (0.0.0.0/0 + ::/0)
# source "192.168.0.0/24" → LAN only
# Add/remove lines as needed.
TCP_RULES="
36796/tcp:any
53317/tcp:192.168.0.0/24
"

UDP_RULES="
53317/udp:192.168.0.0/24
"

# Set to "yes" to add a rate-limited SSH rule (port 22) — safe default for remote machines
# Uses kernel-level rate limiting: blocks IPs that exceed 6 new connections in 30s
ALLOW_SSH="no"

# ─── HELPERS ──────────────────────────────────────────────────────────────────

log()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
ok()   { printf '\033[1;32m[ OK ]\033[0m  %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
die()  { printf '\033[1;31m[FAIL]\033[0m  %s\n' "$*" >&2; exit 1; }

# ─── PREFLIGHT ────────────────────────────────────────────────────────────────

[ "$(id -u)" -eq 0 ] || die "Must be run as root (use sudo)."

# Detect package manager and install ufw if missing
if ! command -v ufw > /dev/null 2>&1; then
    warn "ufw not found — attempting install..."
    if command -v pacman > /dev/null 2>&1; then
        pacman -Sy --noconfirm ufw
    elif command -v apt-get > /dev/null 2>&1; then
        apt-get update -qq && apt-get install -y ufw
    elif command -v dnf > /dev/null 2>&1; then
        dnf install -y ufw
    elif command -v zypper > /dev/null 2>&1; then
        zypper install -y ufw
    else
        die "No supported package manager found. Install ufw manually."
    fi
fi

ok "ufw found: $(ufw version | head -1)"

# ─── DEFAULTS ─────────────────────────────────────────────────────────────────

log "Setting default policies..."
ufw default "$DEFAULT_INCOMING" incoming
ufw default "$DEFAULT_OUTGOING" outgoing

# ─── SSH GUARD ────────────────────────────────────────────────────────────────

if [ "$ALLOW_SSH" = "yes" ]; then
    log "Adding rate-limited SSH rule (max 6 new connections per 30s per IP)..."
    ufw limit 22/tcp
    ok "SSH (port 22) allowed with brute-force rate limiting."
else
    warn "SSH rule skipped (ALLOW_SSH=no). Set to 'yes' if this is a remote machine."
fi

# ─── APPLY RULES ──────────────────────────────────────────────────────────────

apply_rules() {
    rules="$1"
    for rule in $rules; do
        [ -z "$rule" ] && continue
        port_proto="${rule%%:*}"
        source="${rule##*:}"

        if [ "$source" = "any" ]; then
            log "Allowing $port_proto from anywhere..."
            ufw allow in "$port_proto"
        else
            log "Allowing $port_proto from $source..."
            ufw allow in from "$source" to any port "${port_proto%%/*}" proto "${port_proto##*/}"
        fi
    done
}

apply_rules "$TCP_RULES"
apply_rules "$UDP_RULES"

# ─── ENABLE UFW ───────────────────────────────────────────────────────────────

log "Enabling ufw..."
ufw --force enable
ok "ufw enabled."

# ─── ENABLE SYSTEMD SERVICE ───────────────────────────────────────────────────

if command -v systemctl > /dev/null 2>&1; then
    log "Enabling ufw systemd service..."
    systemctl enable ufw > /dev/null 2>&1 || warn "systemctl enable ufw failed — check manually."
    systemctl start  ufw > /dev/null 2>&1 || warn "systemctl start ufw failed — check manually."

    svc_state=$(systemctl is-enabled ufw 2>/dev/null || echo "unknown")
    if [ "$svc_state" = "enabled" ]; then
        ok "ufw.service is enabled (survives reboot)."
    else
        warn "ufw.service state: $svc_state — verify with: systemctl status ufw"
    fi
else
    warn "systemd not found — skipping service enable. Verify boot persistence manually."
fi

# ─── VERIFY ───────────────────────────────────────────────────────────────────

printf '\n'
log "Final ufw status:"
ufw status verbose

printf '\n'
ok "Done. ufw is active, rules applied, and wired to boot."
