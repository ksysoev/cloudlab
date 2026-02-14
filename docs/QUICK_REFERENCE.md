# CloudLab Quick Reference

Quick commands and references for CloudLab operations.

## Terraform Commands

```bash
# Initialize Terraform
cd terraform
terraform init

# Authenticate with Terraform Cloud
terraform login

# Preview changes
terraform plan

# Apply changes
terraform apply

# Show current state
terraform show

# Get outputs
terraform output
terraform output droplet_ip

# Destroy infrastructure (careful!)
terraform destroy
```

## SSH Access

```bash
# Root access
ssh root@<droplet-ip>

# Deployer access (for CI/CD)
ssh deployer@<droplet-ip>

# With specific key
ssh -i ~/.ssh/cloudlab_deployer deployer@<droplet-ip>
```

## Docker Swarm Commands

### Node Management

```bash
# List nodes
docker node ls

# Inspect node
docker node inspect <node-id>

# Update node availability
docker node update --availability active <node-id>

# Get join tokens
docker swarm join-token manager
docker swarm join-token worker
```

### Stack Management

```bash
# List stacks
docker stack ls

# Deploy stack
docker stack deploy -c docker-compose.yml <stack-name>

# Remove stack
docker stack rm <stack-name>

# List services in stack
docker stack services <stack-name>

# List tasks in stack
docker stack ps <stack-name>
```

### Service Management

```bash
# List all services
docker service ls

# Inspect service
docker service inspect <service-name>

# View service logs
docker service logs <service-name>
docker service logs -f <service-name>  # Follow
docker service logs --tail 100 <service-name>  # Last 100 lines

# Scale service
docker service scale <service-name>=3

# Update service
docker service update --force <service-name>
docker service update --image new-image:tag <service-name>

# Remove service
docker service rm <service-name>
```

### Network Management

```bash
# List networks
docker network ls

# Create overlay network
docker network create --driver overlay --attachable <network-name>

# Inspect network
docker network inspect <network-name>

# Remove network
docker network rm <network-name>
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect <volume-name>

# Remove volume
docker volume rm <volume-name>

# Prune unused volumes
docker volume prune
```

### Secrets Management

```bash
# Create secret from stdin
echo "my-secret" | docker secret create <secret-name> -

# Create secret from file
docker secret create <secret-name> /path/to/file

# List secrets
docker secret ls

# Inspect secret
docker secret inspect <secret-name>

# Remove secret
docker secret rm <secret-name>
```

## System Maintenance

### Cleanup

```bash
# Remove unused images
docker image prune -a

# Remove unused containers
docker container prune

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune

# Remove everything unused
docker system prune -a --volumes

# Show disk usage
docker system df
```

### System Info

```bash
# Docker info
docker info

# Swarm status
docker info | grep Swarm

# System resources
docker stats

# Version
docker version
```

### Monitoring

```bash
# Check cloud-init status
cloud-init status

# View cloud-init logs
journalctl -u cloud-init -f

# View Docker daemon logs
journalctl -u docker -f

# System resources
top
htop
free -h
df -h
```

## Grafana Alloy

```bash
# View Alloy service
docker service ls | grep alloy

# Alloy logs
docker service logs monitoring_alloy

# Restart Alloy
docker service update --force monitoring_alloy

# Alloy UI
http://<droplet-ip>:12345
```

## GitHub Secrets

Required secrets for project repositories:

```bash
SWARM_HOST          # Droplet IP address
SWARM_SSH_KEY       # Private SSH key for deployer user
SWARM_USER          # Username (default: deployer)
```

Required secrets for CloudLab repository:

```bash
DO_TOKEN            # DigitalOcean API token
TF_API_TOKEN        # Terraform Cloud API token
```

## Common Tasks

### Deploy a new project

1. Add deployment workflow to project
2. Add GitHub secrets
3. Push to main branch

### Update Terraform configuration

1. Edit terraform files
2. Run `terraform plan`
3. Run `terraform apply`

### SSH into droplet

```bash
ssh deployer@$(cd terraform && terraform output -raw droplet_ip)
```

### View service logs

```bash
ssh deployer@<droplet-ip>
docker service logs -f <stack-name>_<service-name>
```

### Restart a service

```bash
ssh deployer@<droplet-ip>
docker service update --force <stack-name>_<service-name>
```

### Scale a service

```bash
# Via SSH
ssh deployer@<droplet-ip>
docker service scale <stack-name>_<service-name>=3

# Or update docker-compose.yml and redeploy
services:
  app:
    deploy:
      replicas: 3
```

### Remove a project

```bash
ssh deployer@<droplet-ip>
docker stack rm <stack-name>
```

### Backup a volume

```bash
docker run --rm \
  -v <volume-name>:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/backup.tar.gz /data
```

### Restore a volume

```bash
docker run --rm \
  -v <volume-name>:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/backup.tar.gz -C /
```

## Troubleshooting

### Service won't start

```bash
# Check service status
docker service ps <service-name> --no-trunc

# View logs
docker service logs <service-name>

# Check resource constraints
docker service inspect <service-name>
```

### Out of disk space

```bash
# Check disk usage
df -h
docker system df

# Clean up
docker system prune -a --volumes
```

### Cannot access service

```bash
# Check if service is running
docker service ps <service-name>

# Check port mapping
docker service inspect <service-name> | grep -A 10 Ports

# Check firewall
sudo ufw status

# Test from droplet
curl http://localhost:<port>
```

### SSH connection refused

```bash
# Check firewall rules in Terraform
cat terraform/firewall.tf

# Update allowed IPs
# Edit terraform.tfvars: allowed_ssh_ips
terraform apply
```

## Useful Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# CloudLab aliases
alias clssh='ssh deployer@$(cd ~/cloudlab/terraform && terraform output -raw droplet_ip)'
alias cltf='cd ~/cloudlab/terraform'
alias clstack='docker stack ls'
alias clservices='docker service ls'
alias cllogs='docker service logs'
```

## Environment Variables

Set these in your shell:

```bash
# DigitalOcean token
export DO_TOKEN="dop_v1_xxxxx"

# Terraform Cloud token
export TF_TOKEN_app_terraform_io="xxxxx"

# Swarm host
export SWARM_HOST="164.90.xxx.xxx"
```

## Documentation Links

- [Setup Guide](SETUP.md)
- [Deployment Guide](DEPLOYMENT.md)
- [Troubleshooting](TROUBLESHOOTING.md)
- [Docker Swarm Docs](https://docs.docker.com/engine/swarm/)
- [Terraform Docs](https://www.terraform.io/docs)
- [DigitalOcean Docs](https://docs.digitalocean.com/)

## Support

- GitHub Issues: https://github.com/YOUR_USERNAME/cloudlab/issues
- Docker Community: https://forums.docker.com/
- DigitalOcean Community: https://www.digitalocean.com/community/
