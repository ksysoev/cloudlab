# Deployment Guide

This guide explains how to deploy your pet projects to the CloudLab Docker Swarm cluster.

## Overview

Projects can deploy to CloudLab by:
1. Using the reusable GitHub Actions workflow
2. Providing a `docker-compose.yml` file
3. Configuring GitHub Secrets

## Prerequisites

- CloudLab infrastructure is set up (see [SETUP.md](./SETUP.md))
- Your project is in a GitHub repository
- You have admin access to add secrets

## Quick Start

### 1. Add Deployment Workflow to Your Project

Create `.github/workflows/deploy.yml` in your project repository:

```yaml
name: Deploy to CloudLab

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    uses: YOUR_GITHUB_USERNAME/cloudlab/.github/workflows/deploy.yml@main
    with:
      stack_name: my-project-name
      compose_file: docker-compose.yml
    secrets:
      SWARM_HOST: ${{ secrets.SWARM_HOST }}
      SWARM_SSH_KEY: ${{ secrets.SWARM_SSH_KEY }}
      SWARM_USER: ${{ secrets.SWARM_USER }}
```

Replace `YOUR_GITHUB_USERNAME` with your GitHub username or organization.

### 2. Configure GitHub Secrets

In your project repository, add these secrets:
- Settings → Secrets and variables → Actions → New repository secret

**Required secrets:**
- `SWARM_HOST`: Your droplet's IP address (get from `terraform output droplet_ip`)
- `SWARM_SSH_KEY`: Private SSH key for the deployer user
- `SWARM_USER`: Username for deployment (default: `deployer`)

### 3. Create docker-compose.yml

Create a `docker-compose.yml` in your project root:

```yaml
version: '3.8'

services:
  app:
    image: ghcr.io/YOUR_USERNAME/YOUR_REPO:latest
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
    networks:
      - app-network
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure

networks:
  app-network:
    driver: overlay
```

### 4. Deploy!

Push to `main` or manually trigger the workflow:
- Actions → Deploy to CloudLab → Run workflow

## Workflow Inputs

The reusable workflow accepts these inputs:

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `stack_name` | Name of the Docker stack | Yes | - |
| `compose_file` | Path to compose file | No | `docker-compose.yml` |
| `working_directory` | Directory containing compose file | No | `.` |
| `environment` | GitHub environment | No | `production` |
| `build_image` | Build and push Docker image | No | `true` |
| `image_name` | Docker image name | No | repo name |
| `dockerfile_path` | Path to Dockerfile | No | `./Dockerfile` |

### Example: Custom Configuration

```yaml
jobs:
  deploy:
    uses: owner/cloudlab/.github/workflows/deploy.yml@main
    with:
      stack_name: my-api
      compose_file: deployment/docker-compose.prod.yml
      working_directory: ./backend
      environment: production
      build_image: true
      dockerfile_path: ./backend/Dockerfile
    secrets:
      SWARM_HOST: ${{ secrets.SWARM_HOST }}
      SWARM_SSH_KEY: ${{ secrets.SWARM_SSH_KEY }}
```

## Docker Compose Best Practices

### 1. Use Overlay Networks

Each stack should use its own overlay network:

```yaml
networks:
  myapp-network:
    driver: overlay
    attachable: true
```

### 2. Configure Health Checks

```yaml
services:
  app:
    # ...
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### 3. Set Resource Limits

```yaml
services:
  app:
    # ...
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

### 4. Configure Update Strategy

```yaml
services:
  app:
    # ...
    deploy:
      update_config:
        parallelism: 1        # Update 1 container at a time
        delay: 10s            # Wait 10s between updates
        failure_action: rollback
        monitor: 60s
      rollback_config:
        parallelism: 1
        delay: 10s
```

### 5. Use Secrets for Sensitive Data

```yaml
services:
  app:
    # ...
    secrets:
      - db_password
      - api_key

secrets:
  db_password:
    external: true
  api_key:
    external: true
```

Create secrets on the swarm:

```bash
echo "my-secret-password" | docker secret create db_password -
```

### 6. Use Environment Variables

```yaml
services:
  app:
    environment:
      - NODE_ENV=production
      - PORT=8080
      - LOG_LEVEL=info
```

Or use an env file:

```yaml
services:
  app:
    env_file:
      - .env.production
```

## Deployment Process

When you trigger a deployment, the workflow:

1. **Builds the Docker image** (if `build_image: true`)
   - Tags with commit SHA and branch name
   - Pushes to GitHub Container Registry (ghcr.io)

2. **Updates the compose file**
   - Replaces image tags with the new version
   - Creates a deployment-specific compose file

3. **Copies to swarm manager**
   - Transfers compose file via SCP

4. **Deploys the stack**
   - Logs into GHCR on the swarm manager
   - Runs `docker stack deploy`
   - Waits for services to start

5. **Verifies deployment**
   - Checks service status
   - Reports any failed tasks

## Managing Your Stack

### View stack status

```bash
ssh deployer@<your-ip>
docker stack ls
docker stack services <stack-name>
docker stack ps <stack-name>
```

### View logs

```bash
# All services in the stack
docker service logs <stack-name>_<service-name>

# Follow logs
docker service logs -f <stack-name>_<service-name>

# Last 100 lines
docker service logs --tail 100 <stack-name>_<service-name>
```

### Scale a service

```bash
docker service scale <stack-name>_<service-name>=3
```

Or update your `docker-compose.yml` and redeploy.

### Update a service

```bash
# Force update (pulls new image)
docker service update --force <stack-name>_<service-name>

# Update image
docker service update --image ghcr.io/owner/repo:new-tag <stack-name>_<service-name>
```

### Remove a stack

```bash
docker stack rm <stack-name>
```

## Networking

### Expose Services to the Internet

If your service needs to be accessible from the internet:

```yaml
services:
  web:
    ports:
      - "80:8080"      # HTTP
      - "443:8443"     # HTTPS
```

Access your service at: `http://<your-droplet-ip>`

### Service Discovery

Services in the same stack can communicate using service names:

```yaml
services:
  api:
    # ...
  
  worker:
    environment:
      - API_URL=http://api:8080
```

### Shared Networks

To allow multiple stacks to communicate:

1. Create a shared network on the swarm:

```bash
docker network create --driver overlay --attachable shared-network
```

2. Use the external network in your compose file:

```yaml
networks:
  shared-network:
    external: true

services:
  app:
    networks:
      - shared-network
```

## Advanced Topics

### Multi-Stage Deployments

Deploy to staging before production:

```yaml
jobs:
  deploy-staging:
    uses: owner/cloudlab/.github/workflows/deploy.yml@main
    with:
      stack_name: myapp-staging
      environment: staging
    secrets:
      SWARM_HOST: ${{ secrets.SWARM_HOST_STAGING }}
      SWARM_SSH_KEY: ${{ secrets.SWARM_SSH_KEY }}

  deploy-production:
    needs: deploy-staging
    uses: owner/cloudlab/.github/workflows/deploy.yml@main
    with:
      stack_name: myapp-prod
      environment: production
    secrets:
      SWARM_HOST: ${{ secrets.SWARM_HOST }}
      SWARM_SSH_KEY: ${{ secrets.SWARM_SSH_KEY }}
```

### Blue-Green Deployments

Deploy a new version alongside the old:

1. Deploy with a different stack name:
   ```yaml
   stack_name: myapp-green
   ```

2. Test the new version

3. Switch traffic (update DNS or load balancer)

4. Remove the old stack:
   ```bash
   docker stack rm myapp-blue
   ```

### Deploying Without Building

If you build images elsewhere (e.g., separate CI pipeline):

```yaml
jobs:
  deploy:
    uses: owner/cloudlab/.github/workflows/deploy.yml@main
    with:
      stack_name: myapp
      build_image: false  # Don't build, just deploy
    secrets:
      SWARM_HOST: ${{ secrets.SWARM_HOST }}
      SWARM_SSH_KEY: ${{ secrets.SWARM_SSH_KEY }}
```

Your compose file should specify the full image:

```yaml
services:
  app:
    image: ghcr.io/owner/repo:v1.2.3
```

## Troubleshooting

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common deployment issues.

## Examples

### Simple Node.js App

```yaml
version: '3.8'

services:
  app:
    image: ghcr.io/owner/my-node-app:latest
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    networks:
      - app-network
    deploy:
      replicas: 2
      restart_policy:
        condition: on-failure

networks:
  app-network:
    driver: overlay
```

### Go API with PostgreSQL

```yaml
version: '3.8'

services:
  api:
    image: ghcr.io/owner/my-api:latest
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=postgres://postgres:password@db:5432/mydb
    networks:
      - app-network
    depends_on:
      - db
    deploy:
      replicas: 2

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_PASSWORD=password
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - app-network
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager

volumes:
  db-data:

networks:
  app-network:
    driver: overlay
```

### Static Website with Nginx

```yaml
version: '3.8'

services:
  web:
    image: ghcr.io/owner/my-website:latest
    ports:
      - "80:80"
    networks:
      - web-network
    deploy:
      replicas: 2

networks:
  web-network:
    driver: overlay
```

## Next Steps

- Learn about [monitoring and logging](./TROUBLESHOOTING.md#viewing-logs)
- Set up [SSL certificates](./TROUBLESHOOTING.md#ssl-certificates)
- Configure [custom domains](./TROUBLESHOOTING.md#custom-domains)
