# Example: Simple Web App

This is an example of how to deploy a simple web application to CloudLab.

## Project Structure

```
simple-web-app/
├── .github/
│   └── workflows/
│       └── deploy.yml          # Deployment workflow
├── Dockerfile                   # Container image
├── docker-compose.yml           # Swarm deployment config
├── index.html                   # Application code
└── README.md                    # This file
```

## Setup

1. **Copy these files to your project repository**

2. **Add GitHub Secrets** (Settings → Secrets → Actions):
   - `SWARM_HOST`: Your droplet IP
   - `SWARM_SSH_KEY`: Deployer SSH private key
   - `SWARM_USER`: `deployer`

3. **Update the workflow file** (`.github/workflows/deploy.yml`):
   - Replace `YOUR_USERNAME` with your GitHub username

4. **Push to main branch** → automatic deployment!

## Files

### `.github/workflows/deploy.yml`

```yaml
name: Deploy to CloudLab

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    uses: YOUR_USERNAME/cloudlab/.github/workflows/deploy.yml@main
    with:
      stack_name: simple-web-app
    secrets:
      SWARM_HOST: ${{ secrets.SWARM_HOST }}
      SWARM_SSH_KEY: ${{ secrets.SWARM_SSH_KEY }}
      SWARM_USER: ${{ secrets.SWARM_USER }}
```

### `Dockerfile`

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 80
```

### `docker-compose.yml`

```yaml
version: '3.8'

services:
  web:
    image: ghcr.io/YOUR_USERNAME/simple-web-app:latest
    ports:
      - "8080:80"
    networks:
      - web-network
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure

networks:
  web-network:
    driver: overlay
```

### `index.html`

```html
<!DOCTYPE html>
<html>
<head>
    <title>Simple Web App</title>
</head>
<body>
    <h1>Hello from CloudLab!</h1>
    <p>This app is running on Docker Swarm.</p>
</body>
</html>
```

## Deployment

1. Push to main:
   ```bash
   git add .
   git commit -m "Deploy to CloudLab"
   git push
   ```

2. GitHub Actions will:
   - Build the Docker image
   - Push to GitHub Container Registry
   - Deploy to your swarm cluster

3. Access your app:
   ```
   http://<your-droplet-ip>:8080
   ```

## Managing

```bash
# SSH to droplet
ssh deployer@<droplet-ip>

# View status
docker stack services simple-web-app

# View logs
docker service logs -f simple-web-app_web

# Scale
docker service scale simple-web-app_web=4

# Remove
docker stack rm simple-web-app
```

## Next Steps

- Add a database (see `examples/web-app-with-postgres/`)
- Add SSL with Traefik
- Add health checks
- Configure environment variables
