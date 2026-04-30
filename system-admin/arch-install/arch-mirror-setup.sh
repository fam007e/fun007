#!/bin/bash
# =============================================================================
# Arch Linux Mirror One-Click Setup Script (2026 edition)
# Turns a fresh Arch server into a Tier-2 ready Arch mirror
# =============================================================================

set -euo pipefail

echo "========================================================"
echo "    Arch Linux Mirror Automatic Setup Script"
echo "    This will turn your server into a public mirror"
echo "========================================================"

# 1. Update system fully
echo "Updating system..."
pacman -Syu --noconfirm

# 2. Install required packages
echo "Installing required packages..."
pacman -S --noconfirm --needed \
    nginx-mainline rsync curl wget \
    cronie btrfs-progs smartmontools \
    vnstat iftop iotop htop

# 3. Create mirror user (dedicated, not nobody)
# Using nobody for a persistent service that owns files is wrong:
# nobody is for transient/NFS use. A dedicated user is the correct approach.
if ! id -u archmirror &>/dev/null; then
    useradd --system --no-create-home --shell /usr/bin/nologin archmirror
fi

# 4. Create mirror directory (100GB+ for packages only; 5TB+ for full Tier-1)
echo "Creating mirror directory..."
mkdir -p /srv/mirror/archlinux
chown archmirror:archmirror /srv/mirror/archlinux
chmod 755 /srv/mirror/archlinux

# 5. Initial full sync
# Run as archmirror so all files are owned by the sync user from the start.
# If root creates files here, the hourly sync (also archmirror) cannot
# delete or overwrite them, leaving stale packages indefinitely.
echo "Starting initial full sync from official Arch mirror..."
echo "This can take 6-30 hours depending on bandwidth."

sudo -u archmirror rsync -avHAXh --progress --delete-after --delay-updates \
    --timeout=600 --contimeout=60 \
    rsync://rsync.archlinux.org/archlinux/ /srv/mirror/archlinux/

echo "Initial sync finished!"

# 6. Systemd timer for 2-hour sync
# Arch mirror guidelines: sync no more than once per hour; 2h is preferred.
# Checking lastupdate before a full rsync avoids wasting bandwidth when
# upstream hasn't changed (which is most of the time).
cat > /etc/systemd/system/arch-mirror-sync.service <<'EOF'
[Unit]
Description=Arch Linux mirror synchronization
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=archmirror
Group=archmirror
Nice=19
IOSchedulingClass=2
IOSchedulingPriority=7

# Only do a full rsync if upstream has actually updated.
# This is the standard approach recommended in the Arch mirror guide.
ExecStart=/bin/bash -c '\
    UPSTREAM_TS=$(rsync rsync://rsync.archlinux.org/archlinux/lastupdate 2>/dev/null | tr -d "\n"); \
    LOCAL_TS=$(cat /srv/mirror/archlinux/lastupdate 2>/dev/null | tr -d "\n" || echo 0); \
    if [ "$UPSTREAM_TS" = "$LOCAL_TS" ]; then \
        echo "Mirror up to date (lastupdate: $LOCAL_TS), skipping sync."; \
        exit 0; \
    fi; \
    rsync -rtlvH --delete-after --delay-updates --safe-links \
        --timeout=600 --contimeout=60 --bwlimit=0 \
        rsync://rsync.archlinux.org/archlinux/ /srv/mirror/archlinux/ && \
    echo "Sync complete. New lastupdate: $UPSTREAM_TS"'

[Install]
WantedBy=multi-user.target
EOF

cat > /etc/systemd/system/arch-mirror-sync.timer <<'EOF'
[Unit]
Description=Arch Linux mirror synchronization (every 2 hours)
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

# 7. Nginx with performance settings
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
            limit_rate 0;
        }
    }
}
EOF

systemctl enable --now nginx

# 8. BBR and network performance tweaks
echo "Enabling BBR and network optimizations..."
cat > /etc/sysctl.d/99-mirror-performance.conf <<'EOF'
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_slow_start_after_idle = 0
vm.swappiness = 1
EOF
sysctl -p /etc/sysctl.d/99-mirror-performance.conf

# 9. vnstat for traffic monitoring
# Auto-detect the default network interface rather than assuming eth0.
echo "Setting up traffic monitoring..."
DEFAULT_IFACE=$(ip route show default | awk '/default/ {print $5; exit}')
if [ -z "$DEFAULT_IFACE" ]; then
    echo "WARNING: Could not detect default network interface. Configure vnstat manually."
else
    echo "Detected interface: $DEFAULT_IFACE"
    systemctl enable --now vnstat
    vnstat --add -i "$DEFAULT_IFACE" || true
fi

# 10. Final instructions
echo "========================================================"
echo "   YOUR ARCH LINUX MIRROR IS READY!"
echo "========================================================"
PUBLIC_IP=$(curl -4s ifconfig.io 2>/dev/null || echo "<your-ip>")
echo "Mirror URL: http://${PUBLIC_IP}/"
echo ""
echo "Next steps:"
echo "1. Point a domain at this server and set up TLS (certbot + nginx)."
echo "   HTTPS is required for Tier-1 listing; strongly recommended otherwise."
echo ""
echo "2. Submit a mirror request:"
echo "   https://gitlab.archlinux.org/archlinux/infrastructure/-/issues"
echo "   Use the 'New Mirror' issue template. Provide:"
echo "     - HTTP(S) URL"
echo "     - Country"
echo "     - Bandwidth estimate"
echo "     - Admin contact"
echo ""
echo "3. Monitor traffic: vnstat -m -i $DEFAULT_IFACE"
echo "4. Check sync logs: journalctl -u arch-mirror-sync.service"
echo "========================================================"
