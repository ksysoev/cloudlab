#!/bin/bash
# Script to deploy Grafana Alloy to the Docker Swarm cluster
# Run this manually or automatically after swarm initialization

set -e

echo "=== Deploying Grafana Alloy ==="

ALLOY_DIR="/opt/cloudlab/alloy"
STACK_NAME="monitoring"

# Check if Docker Swarm is active
if ! docker info | grep -q "Swarm: active"; then
    echo "Error: Docker Swarm is not active"
    exit 1
fi

# Check if Alloy configuration exists
if [ ! -f "$ALLOY_DIR/docker-compose.yml" ]; then
    echo "Error: Alloy docker-compose.yml not found at $ALLOY_DIR"
    exit 1
fi

if [ ! -f "$ALLOY_DIR/config.alloy" ]; then
    echo "Warning: Alloy config.alloy not found at $ALLOY_DIR"
    echo "Using default configuration..."
fi

# Deploy Alloy stack
echo "Deploying Alloy stack to swarm..."
cd "$ALLOY_DIR"
docker stack deploy -c docker-compose.yml "$STACK_NAME"

echo ""
echo "Waiting for services to start..."
sleep 5

# Check deployment status
echo ""
echo "=== Deployment Status ==="
docker stack services "$STACK_NAME"

echo ""
echo "=== Alloy Tasks ==="
docker service ps "${STACK_NAME}_alloy"

echo ""
echo "✓ Grafana Alloy deployment initiated"
echo "  Access Alloy UI at: http://$(hostname -I | awk '{print $1}'):12345"
echo ""
echo "To check logs: docker service logs ${STACK_NAME}_alloy"
echo "To remove stack: docker stack rm ${STACK_NAME}"
