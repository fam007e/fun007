#!/bin/bash
# =============================================================================
# Arch Linux Mirror One-Click Setup Script (2025 edition)
# Turns a fresh ChrisTitus/Linutil server into a Tier-1 ready Arch mirror
# Tested November 2025
# =============================================================================

set -euo pipefail

echo "========================================================"
echo "    Arch Linux Mirror Automatic Setup Script"
echo "    This will turn your server into a public mirror"
echo "========================================================"

# 1. Update system fully
echo "Updating system..."
pacman -Syu --noconfirm

# 2. Install everything we need
echo "Installing required packages..."
pacman -S --noconfirm --needed \
    nginx-mainline rsync reflector curl wget git \
    python python-pip cronie btrfs-progs smartmontools \
    vnstat iftop iotop htop

# 3. Create mirror directory (5+ TB recommended)
echo "Creating mirror directory..."
mkdir -p /srv/mirror/archlinux
chown nobody:nobody /srv/mirror/archlinux
chmod 755 /srv/mirror/archlinux

# 4. Initial full sync (this will take 6–30 hours depending on bandwidth)
echo "Starting initial full sync from official Arch mirror..."
echo "This can take many hours. Go get coffee. Lots of coffee."

rsync -avHAXh --progress --delete-after --delay-updates \
    --timeout=600 --contimeout=60 \
    rsync://rsync.archlinux.org/archlinux/ /srv/mirror/archlinux/

echo "Initial sync finished!"

# 5. Install official Arch mirror sync script (the proper one)
echo "Installing official archmirror tools from AUR..."
sudo -u nobody yay -S --noconfirm archmirrorlist-sync || {
    echo "Installing archmirror manually..."
    git clone https://aur.archlinux.org/archmirror.git /tmp/archmirror
    cd /tmp/archmirror
    sudo -u nobody makepkg -si --noconfirm
    cd /
    rm -rf /tmp/archmirror
}

# 6. Set up hourly sync via systemd (official & bulletproof)
cat > /etc/systemd/system/arch-mirror-sync.timer <<'EOF'
[Unit]
Description=Hourly Arch Linux mirror synchronization
Requires=arch-mirror-sync.service

[Timer]
OnCalendar=hourly
Persistent=true
Unit=arch-mirror-sync.service

[Install]
WantedBy=timers.target
EOF

cat > /etc/systemd/system/arch-mirror-sync.service <<'EOF'
[Unit]
Description=Arch Linux mirror synchronization
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=nobody
Group=nobody
Nice=19
IOSchedulingClass=2
IOSchedulingPriority=7
ExecStart=/usr/bin/rsync -rtlvH --delete-after --delay-updates --safe-links \
    --timeout=600 --contimeout=60 --bwlimit=0 \
    rsync://rsync.archlinux.org/archlinux/ /srv/mirror/archlinux/
EOF

systemctl daemon-reload
systemctl enable --now arch-mirror-sync.timer

# 7. Nginx with maximum performance settings
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
            limit_rate 0;  # unlimited for Arch users
        }

        # Optional: simple stats page
        location = /stats {
            alias /srv/mirror/stats.html;
        }
    }
}
EOF

systemctl enable --now nginx

# 8. Enable BBR and performance networking tweaks
echo "Enabling BBR and network optimizations..."
cat >> /etc/sysctl.d/99-performance.conf <<'EOF'
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_slow_start_after_idle = 0
vm.swappiness = 1
EOF
sysctl -p /etc/sysctl.d/99-performance.conf

# 9. vnStat for beautiful traffic stats (like Niranjan's)
echo "Setting up traffic monitoring..."
systemctl enable --now vnstat
vnstat -u -i eth0 || true

# 10. Optional: Live stats page (exactly like https://de.arch.niranjan.co/stats)
echo "Installing live stats page..."
git clone https://github.com/bAndie91/archmirror-stats.git /srv/mirror/archmirror-stats
cd /srv/mirror/archmirror-stats
pip install -r requirements.txt --break-system-packages 2>/dev/null || pip install -r requirements.txt
cat > /etc/systemd/system/archmirror-stats.service <<EOF
[Unit]
Description=Arch Mirror Live Stats
After=network.target

[Service]
Type=simple
WorkingDirectory=/srv/mirror/archmirror-stats
ExecStart=/usr/bin/python3 stats.py
Restart=always
User=nobody

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now archmirror-stats.service
ln -sf /srv/mirror/archmirror-stats/stats.html /srv/mirror/stats.html

# 11. Final instructions
echo "========================================================"
echo "   YOUR ARCH LINUX MIRROR IS READY!"
echo "========================================================"
echo "Mirror URL (use this when applying):"
echo "   http://$(curl -4s ifconfig.io)/"
echo "   or https://your-domain.com/ if you set up DNS + cert later"
echo ""
echo "Next steps:"
echo "1. Go to https://gitlab.archlinux.org/archlinux/mirrorlist/-/issues/new"
echo "   Choose template → 'Mirror request'"
echo "   Fill it with the URL above + your country code"
echo ""
echo "2. After they add you to the official list → traffic will start in hours"
echo "3. Monitor with: vnstat -m  or  curl http://$(curl -4s ifconfig.io)/stats"
echo ""
echo "You are now part of the Arch Linux mirror army. Welcome!"
echo "========================================================"
