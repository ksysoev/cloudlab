#!/usr/bin/env bash
# 03-security.sh - UFW firewall, fail2ban, SSH hardening
# Runs as root inside the Packer build droplet.
#
# SSH_PORT is passed as an environment variable from the Packer template
# (environment_vars block). Default matches group_vars/all.yml.
set -euo pipefail

SSH_PORT="${SSH_PORT:-1923}"

echo "==> [03-security] Configuring UFW firewall (SSH port: ${SSH_PORT})..."

# Reset to a clean state so repeated builds are idempotent
ufw --force reset

ufw default deny incoming
ufw default allow outgoing

# SSH on custom port
ufw allow "${SSH_PORT}/tcp" comment "SSH custom port"

# Web traffic
ufw allow 80/tcp comment "HTTP"
ufw allow 443/tcp comment "HTTPS TCP"
ufw allow 443/udp comment "HTTPS UDP (HTTP/3 / QUIC)"

# Application ports (mirror of firewall.tf inbound_rules)
ufw allow 8081/tcp comment "Custom app"
ufw allow 8388/tcp comment "Outline VPN Shadowsocks TCP"
ufw allow 8388/udp comment "Outline VPN Shadowsocks UDP"
ufw allow 8443/tcp comment "Outline VPN Management API"

# make-it-public TCP edge server port range
ufw allow 10000:10999/tcp comment "make-it-public edge"

# Internal Docker services (Docker network CIDR only)
ufw allow from 10.0.0.0/8 to any port 8082 proto tcp comment "8082 internal Docker"

ufw --force enable

echo "==> [03-security] UFW status:"
ufw status verbose

echo "==> [03-security] Enabling fail2ban..."
systemctl enable fail2ban

echo "==> [03-security] Hardening SSH..."
# Remove the DO default sshd drop-in if present at build time.
# Note: cloud-init may recreate it on first boot of the deployed droplet,
# but 00-custom-port.conf sorts before 50-cloud-init.conf so our settings
# (Port, PermitRootLogin, PasswordAuthentication) always take precedence.
rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf

# Write SSH hardening config with the configured SSH port.
# Named 00-custom-port.conf so it sorts FIRST among all drop-in files,
# ensuring our settings (Port, PermitRootLogin) take priority over any
# drop-in that cloud-init or other tools might add later.
cat >/etc/ssh/sshd_config.d/00-custom-port.conf <<EOF
Port ${SSH_PORT}
PermitRootLogin no
PasswordAuthentication no
EOF

cat >/etc/fail2ban/jail.local <<EOF
[sshd]
enabled  = true
port     = ${SSH_PORT}
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 5
bantime  = 3600
EOF

# Validate the final sshd config before the snapshot is taken.
# In non-booted image build environments, /run/sshd may be absent.
mkdir -p /run/sshd
chmod 0755 /run/sshd
sshd -t && echo "==> [03-security] sshd config validation passed."

echo "==> [03-security] Done."
