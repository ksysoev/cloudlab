#!/usr/bin/env bash
# 01-base.sh — Base system setup
# Translated from Ansible roles: bootstrap + common
# Runs as root inside the Packer build droplet.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

APT_OPTS=(
  -o DPkg::Lock::Timeout=300
  -o Acquire::Retries=5
)

echo "==> [01-base] Updating apt cache and upgrading packages..."
apt-get "${APT_OPTS[@]}" update -qq
apt-get "${APT_OPTS[@]}" upgrade -y -qq

echo "==> [01-base] Installing base packages..."
apt-get "${APT_OPTS[@]}" install -y -qq \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  unattended-upgrades \
  fail2ban \
  ufw \
  jq \
  python3 \
  python3-apt

echo "==> [01-base] Configuring automatic security updates..."
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

echo "==> [01-base] Creating deployer group and user..."
groupadd -f deployer
# Create user without a password (locked); SSH key injected via cloud-init at deploy time
id deployer &>/dev/null || useradd \
  --create-home \
  --gid deployer \
  --groups users \
  --shell /bin/bash \
  --password '!' \
  deployer

# Passwordless sudo for deployer
cat > /etc/sudoers.d/deployer <<'EOF'
deployer ALL=(ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/deployer
visudo -cf /etc/sudoers.d/deployer

# Pre-create .ssh dir so cloud-init write_files can populate authorized_keys
# reliably on first boot without needing to create the directory itself.
mkdir -p /home/deployer/.ssh
chmod 0700 /home/deployer/.ssh
chown deployer:deployer /home/deployer/.ssh

echo "==> [01-base] Creating cloudlab directory structure..."
mkdir -p /opt/cloudlab/{scripts,stacks}
chown -R deployer:deployer /opt/cloudlab

echo "==> [01-base] Done."
