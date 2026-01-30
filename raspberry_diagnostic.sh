#!/usr/bin/env bash

# ------------------------------------------------------------
# raspberry_diagnostic.sh
#
#   Collects the most useful diagnostic information from a Raspberry‑Pi.
#   The data is stored in a compressed tar archive that contains:
#       * System & kernel details
#       * CPU / memory / storage stats
#       * Network configuration & status
#       * Running services, logs and boot messages
#       * Configuration files that are likely to be relevant
#
#   Usage:  sudo ./raspberry_diagnostic.sh [output_dir]
#
#   Requires: tar, gzip, systemctl, journalctl (systemd), lsb_release
# ------------------------------------------------------------

set -euo pipefail

# ------------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------------

timestamp() {
    date '+%Y-%m-%d_%H-%M-%S'
}

log() {
    echo "[$(timestamp)] $*"
}

die() {
    log "$1" >&2
    exit 1
}

# ------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------

# Where to put the resulting archive (default: current dir)
OUTDIR=${1:-$(pwd)}

# Temporary working directory
WORKDIR=$(mktemp -d)

cleanup() {
    rm -rf "$WORKDIR"
}
trap cleanup EXIT

# ------------------------------------------------------------------
# 1. Basic system information
# ------------------------------------------------------------------

log "Collecting basic system info..."
cat <<EOF >"$WORKDIR/basic-info.txt"
Hostname: $(hostname)
OS:          $(lsb_release -ds 2>/dev/null || echo "Unknown")
Kernel:      $(uname -srmpv)
Uptime:      $(uptime -p)
CPU model:   $(grep -m1 'model name' /proc/cpuinfo | cut -d':' -f2- | tr -s ' ')
CPU cores:   $(nproc)
Arch:        $(uname -m)
EOF

# ------------------------------------------------------------------
# 2. CPU, memory & storage
# ------------------------------------------------------------------

log "Collecting CPU/memory/storage stats..."
cat <<EOF >"$WORKDIR/system-stats.txt"
=== CPU ==========================================================
$(lscpu)

=== Memory =========================================================
$(free -h)

=== Storage =======================================================
$(lsblk -o NAME,SIZE,MOUNTPOINT,TYPE,FSTYPE -a)
EOF

# ------------------------------------------------------------------
# 3. Disk usage & file system health
# ------------------------------------------------------------------

log "Collecting disk usage and health..."
df -h >"$WORKDIR/df.txt"
du -sh /home/* >"$WORKDIR/home-usage.txt"

# If smartctl is available, show SMART data for each block device
if command -v smartctl >/dev/null 2>&1; then
    log "Collecting SMART data..."
    for dev in $(lsblk -dn -o NAME | grep 'mmcblk\|sd'); do
        echo "=== SMART data: /dev/$dev ===" >>"$WORKDIR/smart.txt"
        smartctl -a "/dev/$dev" 2>/dev/null || echo "No SMART support on /dev/$dev"
    done
fi

# ------------------------------------------------------------------
# 4. Network configuration & status
# ------------------------------------------------------------------

log "Collecting network info..."
{
    echo "=== ifconfig ==="
    ifconfig -a
    echo
    echo "=== ip addr ==="
    ip address show
    echo
    echo "=== Routing tables ==="
    ip route show
    echo
    echo "=== DNS resolvers ==="
    cat /etc/resolv.conf
} >"$WORKDIR/network.txt"

# Show current connections (requires ss)
if command -v ss >/dev/null 2>&1; then
    ss -tulnp >"$WORKDIR/ss.txt"
fi

# ------------------------------------------------------------------
# 5. Running services & processes
# ------------------------------------------------------------------

log "Collecting service and process information..."
systemctl list-units --type=service --state=running >"$WORKDIR/running-services.txt"
ps auxf >"$WORKDIR/processes.txt"

# ------------------------------------------------------------------
# 6. Boot logs (journalctl) – if systemd is used
# ------------------------------------------------------------------

log "Collecting boot and recent journal logs..."
if command -v journalctl >/dev/null 2>&1; then
    journalctl -b --no-pager >"$WORKDIR/journal.txt"
else
    echo "systemd journal not available." >"$WORKDIR/journal.txt"
fi

# ------------------------------------------------------------------
# 7. System configuration files that are often useful
# ------------------------------------------------------------------

log "Collecting selected config files..."
mkdir -p "$WORKDIR/configs"

cp /etc/hostname "$WORKDIR/configs/"
cp /etc/hosts "$WORKDIR/configs/"
cp /etc/resolv.conf "$WORKDIR/configs/"
cp /etc/network/interfaces "$WORKDIR/configs/" 2>/dev/null
cp /etc/dhcpcd.conf "$WORKDIR/configs/" 2>/dev/null
cp -r /boot/* "$WORKDIR/boot-configs/" 2>/dev/null

# ------------------------------------------------------------------
# 8. Optional: Capture the current environment of installed packages
# ------------------------------------------------------------------

log "Collecting package list..."
dpkg --get-selections >"$WORKDIR/packages.txt"

# ------------------------------------------------------------------
# 9. Create archive
# ------------------------------------------------------------------

OUTFILE="$OUTDIR/raspberry-diagnostics-$(timestamp).tar.gz"
log "Creating archive $OUTFILE ..."
tar -czf "$OUTFILE" -C "$WORKDIR" .

log "Diagnostic data collected successfully."
log "Archive location: $(realpath "$OUTFILE")"

exit 0
