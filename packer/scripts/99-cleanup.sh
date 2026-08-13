#!/usr/bin/env bash
# 99-cleanup.sh — Reset machine-specific state before snapshotting
# Ensures each droplet deployed from this image boots as a clean instance.
set -euo pipefail

echo "==> [99-cleanup] Removing Packer build SSH authorized keys from root..."
rm -f /root/.ssh/authorized_keys
# Keep the .ssh dir itself so DigitalOcean's cloud-init can still write keys

echo "==> [99-cleanup] Removing SSH host keys (regenerated on first boot)..."
rm -f /etc/ssh/ssh_host_*

echo "==> [99-cleanup] Cleaning apt caches..."
apt-get -o DPkg::Lock::Timeout=300 clean
apt-get -o DPkg::Lock::Timeout=300 autoremove -y --purge
rm -rf /var/lib/apt/lists/*

echo "==> [99-cleanup] Removing temporary files..."
rm -rf /tmp/* /var/tmp/*

echo "==> [99-cleanup] Removing DHCP leases..."
rm -f /var/lib/dhcp/*.leases

echo "==> [99-cleanup] Resetting cloud-init so it re-runs on first boot..."
# 'clean --logs' removes all cloud-init state AND log files so the
# new droplet picks up its own user_data on first boot.
cloud-init clean --logs

echo "==> [99-cleanup] Clearing shell history..."
history -c
cat /dev/null > /root/.bash_history

echo "==> [99-cleanup] Done. Image is ready for snapshotting."
