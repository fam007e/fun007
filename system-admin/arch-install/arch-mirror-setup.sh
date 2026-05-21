#!/bin/bash
# =============================================================================
# Arch Linux Mirror One-Click Setup Script (2026 edition)
# Turns a fresh Arch server into a Tier-2 ready Arch mirror.
# =============================================================================

set -euo pipefail

SUDO=""
[ "$EUID" -ne 0 ] && command -v sudo >/dev/null 2>&1 && SUDO="sudo"

echo "========================================================"
echo "    Arch Linux Mirror Automatic Setup Script"
echo "    This will turn your server into a public mirror"
echo "========================================================"

# =============================================================================
# 1. System update
# =============================================================================
echo "Updating system..."
$SUDO pacman -Syu --noconfirm

# =============================================================================
# 2. Install required packages
# =============================================================================
echo "Installing required packages..."
$SUDO pacman -S --noconfirm --needed \
    nginx-mainline rsync curl wget python \
    cronie btrfs-progs smartmontools \
    vnstat iftop iotop htop

# Detect and install microcode
if grep -q "GenuineIntel" /proc/cpuinfo; then
    $SUDO pacman -S --noconfirm --needed intel-ucode
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    $SUDO pacman -S --noconfirm --needed amd-ucode
fi

# =============================================================================
# 3. Mirror user (dedicated service account)
# =============================================================================
if ! id -u archmirror &>/dev/null; then
    useradd --system --no-create-home --shell /usr/bin/nologin archmirror
fi

# =============================================================================
# 4. Mirror directory
# =============================================================================
echo "Creating mirror directory..."
mkdir -p /srv/mirror/archlinux
chown archmirror:archmirror /srv/mirror/archlinux
chmod 755 /srv/mirror/archlinux

# =============================================================================
# 5. Select upstream Tier-1 rsync mirror
# =============================================================================
# Policy: Tier-2 mirrors sync from Tier-1 mirrors, NOT from the Arch master
# (rsync.archlinux.org). We fetch the live mirror status JSON and let the
# admin pick the best Tier-1 rsync source for their region.
# =============================================================================

select_upstream_mirror() {
    echo ""
    echo "Fetching Tier-1 mirror list from archlinux.org..."
    local json
    json=$(curl -sL --max-time 15 'https://archlinux.org/mirrors/status/json/' 2>/dev/null || true)

    if [[ -z "$json" ]]; then
        echo "WARNING: Could not fetch mirror list. Using geo.mirror.pkgbuild.com as fallback."
        ARCH_UPSTREAM="rsync://geo.mirror.pkgbuild.com/archlinux/"
        return
    fi

    # Extract and display Tier-1 rsync mirrors sorted by score (lower = better)
    local mirror_list
    mirror_list=$(python3 - <<PYEOF
import json, sys

raw = json.loads("""$json""".replace('\\\\', '\\\\\\\\'))

mirrors = [
    u for u in raw.get('urls', [])
    if u.get('tier') == 1
    and u.get('protocol') == 'rsync'
    and u.get('active', False)
    and u.get('url', '').startswith('rsync://')
    and u.get('score') is not None
]
mirrors.sort(key=lambda x: x['score'])

for i, m in enumerate(mirrors[:15], 1):
    country = (m.get('country') or 'Unknown')[:20]
    url     = m['url']
    score   = m['score']
    print(f"{i:2}. [{country:<20}] {url}  (score: {score:.2f})")
PYEOF
    )

    if [[ -z "$mirror_list" ]]; then
        echo "WARNING: Could not parse mirror list. Using geo.mirror.pkgbuild.com."
        ARCH_UPSTREAM="rsync://geo.mirror.pkgbuild.com/archlinux/"
        return
    fi

    echo ""
    echo "Available Tier-1 rsync mirrors (sorted best → worst by score):"
    echo "$mirror_list"
    echo ""
    echo "Enter number to select, or press Enter to use #1 (best score),"
    echo "or type a full rsync:// URL for a custom upstream:"
    read -rp "Selection: " selection < /dev/tty

    if [[ -z "$selection" ]]; then
        # Default: first line
        ARCH_UPSTREAM=$(echo "$mirror_list" | head -1 | grep -oP 'rsync://[^ ]+')
    elif [[ "$selection" =~ ^[0-9]+$ ]]; then
        ARCH_UPSTREAM=$(echo "$mirror_list" | sed -n "${selection}p" | grep -oP 'rsync://[^ ]+')
        if [[ -z "$ARCH_UPSTREAM" ]]; then
            echo "Invalid selection. Using #1."
            ARCH_UPSTREAM=$(echo "$mirror_list" | head -1 | grep -oP 'rsync://[^ ]+')
        fi
    elif [[ "$selection" == rsync://* ]]; then
        ARCH_UPSTREAM="$selection"
    else
        echo "Unrecognised input. Using #1."
        ARCH_UPSTREAM=$(echo "$mirror_list" | head -1 | grep -oP 'rsync://[^ ]+')
    fi

    echo "Selected upstream: $ARCH_UPSTREAM"
}

select_upstream_mirror

# =============================================================================
# 6. Initial full sync
# =============================================================================
echo ""
echo "Starting initial full sync from: $ARCH_UPSTREAM"
echo "This can take 6–30 hours depending on bandwidth and mirror size."
echo ""

sudo -u archmirror rsync -avHAXh --progress --delete-after --delay-updates \
    --timeout=600 --contimeout=60 \
    "${ARCH_UPSTREAM}" /srv/mirror/archlinux/

echo "Initial sync complete."

# =============================================================================
# 7. Systemd sync timer (every 2 hours, lastupdate check to skip if unchanged)
# =============================================================================
# The upstream URL is embedded in the service unit. To change it later:
#   edit /etc/systemd/system/arch-mirror-sync.service → Environment=ARCH_UPSTREAM=...
#   systemctl daemon-reload && systemctl restart arch-mirror-sync.timer

cat > /etc/systemd/system/arch-mirror-sync.service <<EOF
[Unit]
Description=Arch Linux mirror synchronisation (Tier-2)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=archmirror
Group=archmirror
Nice=19
IOSchedulingClass=2
IOSchedulingPriority=7
Environment=ARCH_UPSTREAM=${ARCH_UPSTREAM}

# Only do a full rsync when upstream has actually updated.
# Comparing lastupdate timestamps avoids wasting bandwidth on unchanged mirrors.
ExecStart=/bin/bash -c '\
    UPSTREAM_TS=\$(rsync "\${ARCH_UPSTREAM}lastupdate" 2>/dev/null | tr -d "\\n"); \
    LOCAL_TS=\$(cat /srv/mirror/archlinux/lastupdate 2>/dev/null | tr -d "\\n" || echo 0); \
    if [ "\$UPSTREAM_TS" = "\$LOCAL_TS" ]; then \
        echo "Mirror up to date (lastupdate: \$LOCAL_TS). Skipping."; \
        exit 0; \
    fi; \
    rsync -rtlvH --delete-after --delay-updates --safe-links \
        --timeout=600 --contimeout=60 --bwlimit=0 \
        "\${ARCH_UPSTREAM}" /srv/mirror/archlinux/ && \
    echo "Sync complete. New lastupdate: \$UPSTREAM_TS"'

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/arch-mirror-sync.timer <<'EOF'
[Unit]
Description=Arch Linux mirror synchronisation (every 2 hours)
Requires=arch-mirror-sync.service

[Timer]
OnCalendar=*-*-* 00/2:00:00
Persistent=true
Unit=arch-mirror-sync.service

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now arch-mirror-sync.timer

# =============================================================================
# 8. Nginx with performance settings
# =============================================================================
echo "Configuring nginx..."
cat > /etc/nginx/nginx.conf <<'EOF'
user http;
worker_processes auto;
worker_rlimit_nofile 65535;
pid /run/nginx.pid;

events {
    worker_connections 16384;
    multi_accept on;
    use epoll;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 100000;
    types_hash_max_size 2048;

    open_file_cache max=200000 inactive=20m;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log off;
    error_log /var/log/nginx/error.log crit;

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;

        root /srv/mirror/archlinux;
        autoindex on;

        location / {
            # No transfer rate cap — mirrors should be fast.
        }
    }
}
EOF

systemctl enable --now nginx

# =============================================================================
# 9. BBR + network performance sysctl
# =============================================================================
echo "Enabling BBR and network optimisations..."
cat > /etc/sysctl.d/99-mirror-performance.conf <<'EOF'
net.core.default_qdisc         = fq
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_max               = 16777216
net.core.wmem_max               = 16777216
net.ipv4.tcp_rmem               = 4096 87380 16777216
net.ipv4.tcp_wmem               = 4096 65536 16777216
net.ipv4.tcp_slow_start_after_idle = 0
vm.swappiness                   = 1
EOF
sysctl -p /etc/sysctl.d/99-mirror-performance.conf

# =============================================================================
# 10. vnstat traffic monitoring
# =============================================================================
echo "Setting up traffic monitoring..."
DEFAULT_IFACE=$(ip route show default | awk '/default/ {print $5; exit}')
if [[ -z "$DEFAULT_IFACE" ]]; then
    echo "WARNING: Could not detect default network interface. Configure vnstat manually."
else
    echo "Detected interface: $DEFAULT_IFACE"
    systemctl enable --now vnstat
    vnstat --add -i "$DEFAULT_IFACE" || true
fi

# =============================================================================
# Done
# =============================================================================
PUBLIC_IP=$(curl -4s --max-time 5 ifconfig.io 2>/dev/null || echo "<your-ip>")

echo ""
echo "========================================================"
echo "   YOUR ARCH LINUX MIRROR IS READY!"
echo "========================================================"
echo "Upstream:   $ARCH_UPSTREAM"
echo "Mirror URL: http://${PUBLIC_IP}/"
echo ""
echo "Next steps:"
echo "1. Point a domain at this server and set up TLS (certbot + nginx)."
echo "   HTTPS is required for Tier-1 listing."
echo ""
echo "2. Run the hardening script:"
echo "   curl -fsSL <url>/arch-mirror-hardened.sh | sudo bash"
echo ""
echo "3. Submit a mirror request (once synced and stable):"
echo "   https://gitlab.archlinux.org/archlinux/infrastructure/-/issues"
echo "   Template: 'New Mirror'. Include URL, country, bandwidth, admin email."
echo ""
echo "4. Monitor:   vnstat -m -i ${DEFAULT_IFACE:-eth0}"
echo "5. Sync logs: journalctl -u arch-mirror-sync.service"
echo "6. To change upstream later:"
echo "   Edit /etc/systemd/system/arch-mirror-sync.service"
echo "   → Environment=ARCH_UPSTREAM=rsync://new-mirror/archlinux/"
echo "   → systemctl daemon-reload && systemctl restart arch-mirror-sync.timer"
echo "========================================================"
