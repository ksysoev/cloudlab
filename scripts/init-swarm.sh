#!/bin/bash
# Script to initialize Docker Swarm on the manager node
# This script is automatically run by cloud-init during droplet provisioning

set -e

echo "=== CloudLab Swarm Initialization ==="
echo "Starting at: $(date)"

# Get the droplet's public IP address
PUBLIC_IP=$(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)
echo "Public IP: $PUBLIC_IP"

# Check if Docker is running
if ! systemctl is-active --quiet docker; then
    echo "Error: Docker is not running"
    exit 1
fi

# Initialize Docker Swarm if not already initialized
if ! docker info | grep -q "Swarm: active"; then
    echo "Initializing Docker Swarm..."
    docker swarm init --advertise-addr "$PUBLIC_IP"
    echo "✓ Docker Swarm initialized successfully"
else
    echo "✓ Docker Swarm is already active"
fi

# Display Swarm status
echo ""
echo "=== Swarm Status ==="
docker node ls

# Save join tokens for future reference
echo ""
echo "=== Join Tokens ==="
echo "To add a manager node:"
docker swarm join-token manager
echo ""
echo "To add a worker node:"
docker swarm join-token worker

# Create overlay networks for applications
echo ""
echo "=== Creating overlay networks ==="
docker network create --driver overlay --attachable cloudlab-public || echo "Network cloudlab-public already exists"

echo ""
echo "=== Swarm initialization complete! ==="
echo "Completed at: $(date)"
