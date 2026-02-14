#!/bin/bash
# Script to deploy Grafana Alloy to the Docker Swarm cluster
# Run this manually or automatically after swarm initialization
#
# Required environment variables (or set via alloy/.env):
#   GRAFANA_CLOUD_LOGS_URL       - Grafana Cloud Loki push endpoint
#   GRAFANA_CLOUD_LOGS_ID        - Grafana Cloud Loki instance ID
#   GRAFANA_CLOUD_METRICS_URL    - Grafana Cloud Prometheus push endpoint
#   GRAFANA_CLOUD_METRICS_ID     - Grafana Cloud Prometheus instance ID
#   GRAFANA_CLOUD_API_KEY        - Grafana Cloud API key (shared)

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

if [ ! -f "$ALLOY_DIR/config.alloy.tpl" ]; then
    echo "Error: Alloy config.alloy.tpl not found at $ALLOY_DIR"
    exit 1
fi

# Source .env file if it exists (for local/manual deployments)
if [ -f "$ALLOY_DIR/.env" ]; then
    echo "Loading environment variables from $ALLOY_DIR/.env..."
    set -a
    # shellcheck disable=SC1091
    . "$ALLOY_DIR/.env"
    set +a
fi

# Validate required environment variables
MISSING_VARS=0
for var in GRAFANA_CLOUD_LOGS_URL GRAFANA_CLOUD_LOGS_ID GRAFANA_CLOUD_METRICS_URL GRAFANA_CLOUD_METRICS_ID GRAFANA_CLOUD_API_KEY; do
    if [ -z "$(eval echo "\$$var")" ]; then
        echo "Warning: $var is not set"
        MISSING_VARS=$((MISSING_VARS + 1))
    fi
done

if [ "$MISSING_VARS" -gt 0 ]; then
    echo ""
    echo "Some Grafana Cloud credentials are missing."
    echo "Set them via environment variables or create $ALLOY_DIR/.env"
    echo "See alloy/.env.example for the required format."
    echo ""
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
echo "Grafana Alloy deployment initiated"
echo "  Access Alloy UI at: http://$(hostname -I | awk '{print $1}'):12345"
echo ""
echo "To check logs: docker service logs ${STACK_NAME}_alloy"
echo "To remove stack: docker stack rm ${STACK_NAME}"
