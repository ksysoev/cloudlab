#!/usr/bin/env bash
# 04-monitoring.sh — Grafana Alloy installation
# Runs as root inside the Packer build droplet.
#
# Alloy config with Grafana Cloud secrets is NOT written here — it contains
# sensitive credentials that vary per environment. cloud-init writes the
# real config.alloy at first boot (see terraform/cloud-init.yml.tpl).
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

APT_OPTS=(
  -o DPkg::Lock::Timeout=300
  -o Acquire::Retries=5
)

echo "==> [04-monitoring] Adding Grafana apt repository..."
mkdir -p /etc/apt/keyrings

curl -fsSL https://apt.grafana.com/gpg.key \
  | gpg --dearmor --yes -o /etc/apt/keyrings/grafana.gpg

cat > /etc/apt/sources.list.d/grafana.list <<'EOF'
deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main
EOF

echo "==> [04-monitoring] Updating apt cache..."
apt-get "${APT_OPTS[@]}" update -qq

echo "==> [04-monitoring] Installing Grafana Alloy..."
apt-get "${APT_OPTS[@]}" install -y -qq alloy

echo "==> [04-monitoring] Creating alloy system user..."
# The package may already create the user; be idempotent
id alloy &>/dev/null || useradd \
  --system \
  --no-create-home \
  --shell /usr/sbin/nologin \
  alloy

echo "==> [04-monitoring] Adding alloy to docker group..."
usermod -aG docker alloy

echo "==> [04-monitoring] Creating alloy data directory..."
mkdir -p /var/lib/alloy/data
chown -R alloy:alloy /var/lib/alloy
chmod 0755 /var/lib/alloy

echo "==> [04-monitoring] Creating alloy config directory..."
mkdir -p /etc/alloy

# Placeholder config so the service can be enabled without failing syntax checks.
# cloud-init overwrites this with the real secret-bearing config at first boot.
cat > /etc/alloy/config.alloy <<'EOF'
// Placeholder — replaced by cloud-init at first boot with Grafana Cloud credentials.
logging {
  level  = "info"
  format = "logfmt"
}
EOF
chown root:root /etc/alloy/config.alloy
chmod 0644 /etc/alloy/config.alloy

echo "==> [04-monitoring] Configuring Alloy environment defaults..."
cat > /etc/default/alloy <<'EOF'
CONFIG_FILE="/etc/alloy/config.alloy"
EOF

echo "==> [04-monitoring] Enabling Alloy service (started by cloud-init after config is written)..."
# Enable so it starts on reboot automatically; cloud-init starts it explicitly
# once it has written the real config.alloy with the Grafana Cloud secrets.
systemctl enable alloy

echo "==> [04-monitoring] Done."
