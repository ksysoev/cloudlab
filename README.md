# CloudLab

Infrastructure as Code for deploying pet projects to Docker Swarm on DigitalOcean.

## Overview

CloudLab provides a complete infrastructure setup for hosting multiple pet projects on a single DigitalOcean droplet running Docker Swarm. It includes:

- **Terraform** configuration for provisioning infrastructure
- **Docker Swarm** single-node cluster (easily scalable)
- **Grafana Alloy** for logs and metrics collection
- **Reusable GitHub Actions workflow** for easy deployments
- **Complete documentation** for setup and usage

## Features

- **Cost-effective:** ~$12/month for hosting multiple projects
- **Easy deployments:** Simple GitHub Actions workflow integration
- **Automatic SSL:** (Configure Traefik or use project-level SSL)
- **Monitoring:** Built-in Grafana Alloy for observability
- **Scalable:** Start with one node, scale to multi-node cluster
- **Secure:** Non-standard SSH port, firewall rules, key authentication

## Quick Start

### 1. Clone this repository

```bash
git clone https://github.com/YOUR_USERNAME/cloudlab.git
cd cloudlab
```

### 2. Configure GitHub Secrets

This repository needs two secrets for GitHub Actions to work:

1. Go to **Settings → Secrets and variables → Actions**
2. Add these repository secrets:
   - `TF_API_TOKEN` - Your Terraform Cloud API token
   - `DO_TOKEN` - Your DigitalOcean API token

### 3. Set up infrastructure

Follow the [Setup Guide](docs/SETUP.md) to:
- Configure Terraform Cloud
- Set up DigitalOcean API token
- Provision the droplet

Quick setup:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

### 4. Deploy your first project

Add this workflow to your project's `.github/workflows/deploy.yml`:

```yaml
name: Deploy to CloudLab

on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: YOUR_USERNAME/cloudlab/.github/workflows/deploy.yml@main
    with:
      stack_name: my-project
    secrets:
      SWARM_HOST: ${{ secrets.SWARM_HOST }}
      SWARM_SSH_KEY: ${{ secrets.SWARM_SSH_KEY }}
      SWARM_SSH_PORT: ${{ secrets.SWARM_SSH_PORT }}
      SWARM_USER: ${{ secrets.SWARM_USER }}
```

See the [Deployment Guide](docs/DEPLOYMENT.md) for details.

## Documentation

- **[Setup Guide](docs/SETUP.md)** - Initial infrastructure setup
- **[Deployment Guide](docs/DEPLOYMENT.md)** - How to deploy projects
- **[Security Guide](docs/SECURITY.md)** - Security configuration and best practices
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Quick Reference](docs/QUICK_REFERENCE.md)** - Command cheat sheet

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     DigitalOcean Droplet                    │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Docker Swarm Manager                    │  │
│  │                                                      │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐   │  │
│  │  │  Project A │  │  Project B │  │  Project C │   │  │
│  │  │   Stack    │  │   Stack    │  │   Stack    │   │  │
│  │  └────────────┘  └────────────┘  └────────────┘   │  │
│  │                                                      │  │
│  │  ┌────────────────────────────────────────────┐   │  │
│  │  │         Grafana Alloy (Monitoring)         │   │  │
│  │  └────────────────────────────────────────────┘   │  │
│  │                                                      │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  Firewall: SSH (1923), HTTP (80), HTTPS (443), Custom (8081)  │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ GitHub Actions
                           ▼
              ┌────────────────────────┐
              │   Your Project Repos   │
              │  (Build & Deploy)      │
              └────────────────────────┘
```

## Repository Structure

```
cloudlab/
├── terraform/              # Infrastructure as Code
│   ├── providers.tf        # Terraform & provider config
│   ├── variables.tf        # Input variables
│   ├── outputs.tf          # Output values
│   ├── droplet.tf          # Droplet resource
│   ├── firewall.tf         # Firewall rules
│   ├── ssh.tf              # SSH key management
│   ├── main.tf             # Main configuration
│   ├── cloud-init.yaml     # Droplet initialization script
│   └── terraform.tfvars.example
│
├── scripts/                # Helper scripts
│   ├── init-swarm.sh       # Initialize Docker Swarm
│   └── deploy-alloy.sh     # Deploy Grafana Alloy
│
├── alloy/                  # Grafana Alloy configuration
│   ├── docker-compose.yml  # Alloy service definition
│   └── config.alloy        # Alloy configuration
│
├── .github/workflows/      # GitHub Actions workflows
│   ├── deploy.yml          # Reusable deployment workflow
│   └── provision.yml       # Infrastructure provisioning
│
└── docs/                   # Documentation
    ├── SETUP.md            # Setup guide
    ├── DEPLOYMENT.md       # Deployment guide
    └── TROUBLESHOOTING.md  # Troubleshooting guide
```

## Requirements

- **DigitalOcean Account** - [Sign up](https://www.digitalocean.com/)
- **Terraform Cloud Account** - [Sign up](https://app.terraform.io/)
- **GitHub Account** - For hosting code and CI/CD
- **Terraform CLI** (>= 1.0) - [Install](https://developer.hashicorp.com/terraform/install)
- **SSH Keys** - For accessing the droplet

## Technology Stack

- **Cloud Provider:** DigitalOcean
- **IaC Tool:** Terraform with Terraform Cloud backend
- **OS:** Ubuntu 24.04 LTS
- **Container Orchestration:** Docker Swarm
- **CI/CD:** GitHub Actions
- **Container Registry:** GitHub Container Registry (GHCR)
- **Monitoring:** Grafana Alloy → Grafana Cloud
- **Automation:** Cloud-init, Bash scripts

## Cost Breakdown

- **Droplet (s-1vcpu-2gb):** $12/month
- **Terraform Cloud:** Free tier
- **GitHub Actions:** Free tier (2000 minutes/month)
- **GHCR:** Free for public repos
- **Grafana Cloud:** Free tier (14-day retention)
- **DigitalOcean Bandwidth:** 2TB included

**Total: ~$12-15/month**

## Use Cases

Perfect for:
- Personal projects and portfolios
- Side projects and MVPs
- Learning and experimentation
- Development and staging environments
- Small production workloads
- Microservices architecture practice

## Scaling Options

### Vertical Scaling (Bigger Droplet)

```bash
# Edit terraform.tfvars
droplet_size = "s-2vcpu-4gb"  # $24/mo

# Apply changes
terraform apply
```

### Horizontal Scaling (More Nodes)

1. Add worker nodes to `terraform/droplet.tf`
2. Join workers to the swarm
3. Scale services across multiple nodes

### Add More Services

Each project gets its own Docker stack:
- Isolated networks
- Independent scaling
- Easy rollbacks

## Examples

### Deploy a Node.js app

1. Add Dockerfile to your project
2. Add docker-compose.yml
3. Add deployment workflow
4. Push to GitHub → automatic deployment

See [examples in the deployment guide](docs/DEPLOYMENT.md#examples).

## Security

- **Non-Standard SSH Port:** SSH runs on port 1923 (not 22)
- **SSH Key Authentication:** No password authentication
- **Firewall:** Only ports 1923, 80, 443, 8081 (TCP) and 443 (UDP) exposed
- **Ubuntu 24.04 LTS:** Latest LTS release with automatic security updates
- **Secrets Management:** GitHub Secrets + Docker Secrets
- **Fail2ban:** Protection against brute-force attacks
- **UFW Firewall:** Host-based firewall for defense in depth

See [SECURITY.md](docs/SECURITY.md) for detailed security information.

## Monitoring

- **Grafana Alloy** collects logs and metrics
- Sends to **Grafana Cloud** (or local Prometheus/Loki)
- Monitor all services from one dashboard
- Set up alerts for issues

## Contributing

This is a personal infrastructure project, but feel free to:
- Fork for your own use
- Submit issues for bugs
- Suggest improvements via PRs

## Troubleshooting

Common issues and solutions are documented in [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

Quick tips:
- **Can't SSH?** Check firewall rules and SSH keys
- **Deployment fails?** Verify GitHub secrets are set
- **Service won't start?** Check logs with `docker service logs`
- **Out of space?** Run `docker system prune -a`

## License

MIT License - See [LICENSE](LICENSE) file

## Roadmap

Future enhancements:
- [ ] Traefik for automatic SSL and routing
- [ ] Automated backups to DigitalOcean Spaces
- [ ] Multi-region support
- [ ] Database templates (Postgres, Redis, MongoDB)
- [ ] Example projects with different tech stacks
- [ ] Terraform modules for different node sizes
- [ ] Staging environment support

## FAQ

**Q: Can I use this in production?**  
A: Yes, but consider redundancy, backups, and monitoring for production workloads.

**Q: How many projects can I host?**  
A: Depends on resource usage. A $12/mo droplet can handle 5-10 lightweight services.

**Q: Can I use other cloud providers?**  
A: Yes, but you'll need to adapt the Terraform configuration.

**Q: Do I need to know Docker Swarm?**  
A: Basic knowledge helps, but the guides cover everything you need.

**Q: Can I use Kubernetes instead?**  
A: This project uses Docker Swarm for simplicity. For K8s, consider managed services like DOKS.

**Q: How do I add SSL certificates?**  
A: Each project can handle SSL independently, or add Traefik to the swarm for automatic SSL.

## Support

- **Issues:** [GitHub Issues](https://github.com/YOUR_USERNAME/cloudlab/issues)
- **Documentation:** [docs/](docs/)
- **Docker Swarm:** [Official Docs](https://docs.docker.com/engine/swarm/)
- **DigitalOcean:** [Community Tutorials](https://www.digitalocean.com/community/tutorials)

## Acknowledgments

Built with:
- [Terraform](https://www.terraform.io/)
- [Docker Swarm](https://docs.docker.com/engine/swarm/)
- [DigitalOcean](https://www.digitalocean.com/)
- [Grafana Alloy](https://grafana.com/docs/alloy/)
- [GitHub Actions](https://github.com/features/actions)

---

**Happy Deploying!** 🚀

For detailed setup instructions, see [docs/SETUP.md](docs/SETUP.md).
