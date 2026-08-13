#!/usr/bin/env bash
# 02-docker.sh — Docker CE installation
# Translated from Ansible role: docker
# Runs as root inside the Packer build droplet.
#
# NOTE: Docker Swarm init and overlay network creation are intentionally
# NOT done here — they require the real public IP which is only known at
# deploy time. cloud-init handles both (see terraform/cloud-init.yml.tpl).
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "==> [02-docker] Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "==> [02-docker] Adding Docker apt repository..."
cat > /etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable
EOF

echo "==> [02-docker] Updating apt cache..."
apt-get update -qq

echo "==> [02-docker] Installing Docker CE and plugins..."
apt-get install -y -qq \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

echo "==> [02-docker] Creating /etc/docker directory..."
mkdir -p /etc/docker
# daemon.json is uploaded by the Packer file provisioner after this script runs

echo "==> [02-docker] Adding deployer to docker group..."
usermod -aG docker deployer

echo "==> [02-docker] Enabling Docker service (started by cloud-init after Swarm init)..."
# Enable so it starts on boot automatically; cloud-init will also start it
# explicitly before running 'docker swarm init'.
systemctl enable docker

echo "==> [02-docker] Done."
