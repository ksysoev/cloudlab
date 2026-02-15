# CloudLab

Infrastructure as Code for provisioning Docker Swarm on DigitalOcean.

## Overview

CloudLab provides a complete infrastructure solution for running Docker Swarm on DigitalOcean with proper configuration management. It uses a two-layer approach:

- **Terraform** for infrastructure provisioning (droplet, networking, SSH keys)
- **Ansible** for OS and service configuration (Docker, monitoring, security)
- **Docker Swarm** single-node cluster (easily scalable)
- **Grafana Alloy** for logs and metrics collection
- **Security hardening** with firewall, SSH configuration, and best practices
- **Complete automation** via GitHub Actions CI/CD

## Features

- **Cost-effective:** ~$12/month for a production-ready swarm cluster
- **Production-ready:** Hardened security configuration out of the box
- **Infrastructure as Code:** Terraform for infrastructure, Ansible for configuration
- **Stateful deployments:** Changes don't recreate the droplet (preserves data)
- **Idempotent configuration:** Safe to run repeatedly, only changes what's needed
- **Monitoring:** Built-in Grafana Alloy for observability
- **Scalable:** Start with one node, scale to multi-node cluster
- **Secure:** Non-standard SSH port, firewall rules, key authentication
- **Fully automated:** GitHub Actions runs Terraform and Ansible on every push

## Quick Start

### 1. Clone this repository

```bash
git clone https://github.com/YOUR_USERNAME/cloudlab.git
cd cloudlab
```

### 2. Configure GitHub Secrets

This repository needs several secrets for GitHub Actions to work:

1. Go to **Settings → Secrets and variables → Actions → New repository secret**
2. Add these secrets:
   - `TF_API_TOKEN` - Your Terraform Cloud API token
   - `SSH_PRIVATE_KEY` - Your SSH private key for the deployer user
   - `GRAFANA_CLOUD_LOGS_URL` - Grafana Cloud Loki endpoint (optional)
   - `GRAFANA_CLOUD_LOGS_ID` - Grafana Cloud Loki instance ID (optional)
   - `GRAFANA_CLOUD_METRICS_URL` - Grafana Cloud Prometheus endpoint (optional)
   - `GRAFANA_CLOUD_METRICS_ID` - Grafana Cloud Prometheus instance ID (optional)
   - `GRAFANA_CLOUD_API_KEY` - Grafana Cloud API key (optional)

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

### 3. Verify the deployment

After Terraform completes, test SSH access:

```bash
# Get the droplet IP from outputs
terraform output droplet_ip

# Connect to the droplet (using deployer user - root SSH is disabled for security)
ssh -p 1923 deployer@<droplet-ip>

# Verify Docker Swarm
docker node ls
docker service ls
```

Your infrastructure is now ready! Deploy workloads using `docker stack deploy` or integrate with your CI/CD pipeline.

## Documentation

- **[Setup Guide](docs/SETUP.md)** - Initial infrastructure setup
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
                           │                    │
                  Terraform │                    │ Ansible
                  (infra)   │                    │ (config)
                           ▼                    ▼
              ┌────────────────────┐  ┌────────────────────┐
              │   Provision        │  │   Configure        │
              │   - Droplet        │  │   - Docker         │
              │   - SSH Keys       │  │   - Security       │
              │   - Firewall       │  │   - Monitoring     │
              └────────────────────┘  └────────────────────┘
                           │                    │
                           └────────┬───────────┘
                                    │
                           GitHub Actions CI/CD
```

### Two-Layer Approach

**Layer 1: Infrastructure (Terraform)**
- Creates the droplet with minimal cloud-init
- Configures networking and firewall
- Manages SSH keys
- **Result:** A bare Ubuntu server ready for configuration

**Layer 2: Configuration (Ansible)**
- Installs and configures Docker + Swarm
- Sets up security (UFW, fail2ban, SSH hardening)
- Deploys Grafana Alloy monitoring
- Creates directory structure
- **Result:** A fully configured, production-ready server

**Benefits:**
- Changes to configuration don't recreate the droplet
- Safe for stateful workloads (databases, volumes persist)
- Idempotent - can run configuration multiple times safely
- Fast updates - only changes what's needed

## Repository Structure

```
cloudlab/
├── terraform/              # Infrastructure provisioning (Terraform)
│   ├── providers.tf        # Terraform & provider config
│   ├── variables.tf        # Input variables
│   ├── outputs.tf          # Output values
│   ├── droplet.tf          # Droplet resource
│   ├── firewall.tf         # Firewall rules
│   ├── ssh.tf              # SSH key management
│   ├── main.tf             # Main configuration
│   ├── cloud-init.yaml     # Minimal bootstrap (Python + SSH)
│   └── terraform.tfvars.example
│
├── ansible/                # Configuration management (Ansible)
│   ├── ansible.cfg         # Ansible configuration
│   ├── inventory/
│   │   └── production.py   # Dynamic inventory from Terraform
│   ├── group_vars/
│   │   └── all.yml         # Default variables
│   ├── playbooks/
│   │   └── site.yml        # Main playbook
│   ├── roles/
│   │   ├── common/         # Base system setup
│   │   ├── security/       # Firewall, SSH hardening
│   │   ├── docker/         # Docker + Swarm
│   │   └── monitoring/     # Grafana Alloy
│   └── README.md           # Ansible documentation
│
├── .github/workflows/      # CI/CD automation
│   ├── provision.yml       # Terraform (infrastructure)
│   ├── configure.yml       # Ansible (configuration)
│   └── test.yml            # Terraform validation
│
└── docs/                   # Documentation
    ├── SETUP.md            # Setup guide
    ├── SECURITY.md         # Security guide
    ├── TROUBLESHOOTING.md  # Troubleshooting guide
    ├── QUICK_REFERENCE.md  # Command cheat sheet
    └── PRE_MERGE_CHECKLIST.md  # Pre-deployment checklist
```

## Requirements

- **DigitalOcean Account** - [Sign up](https://www.digitalocean.com/)
- **Terraform Cloud Account** - [Sign up](https://app.terraform.io/)
- **GitHub Account** - For hosting code and CI/CD
- **Terraform CLI** (>= 1.0) - [Install](https://developer.hashicorp.com/terraform/install)
- **SSH Keys** - For accessing the droplet

## Technology Stack

- **Cloud Provider:** DigitalOcean
- **Infrastructure as Code:** Terraform with Terraform Cloud backend
- **Configuration Management:** Ansible
- **OS:** Ubuntu 24.04 LTS
- **Container Orchestration:** Docker Swarm
- **CI/CD:** GitHub Actions
- **Container Registry:** GitHub Container Registry (GHCR)
- **Monitoring:** Grafana Alloy → Grafana Cloud
- **Automation:** Cloud-init (bootstrap only), Ansible (full config)

## Cost Breakdown

- **Droplet (s-1vcpu-2gb):** $12/month
- **Terraform Cloud:** Free tier
- **GitHub Actions:** Free tier (2000 minutes/month)
- **Grafana Cloud:** Free tier (14-day retention)
- **DigitalOcean Bandwidth:** 2TB included

**Total: ~$12/month**

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

Deploy additional services to your swarm:
- Each service gets its own Docker stack
- Isolated networks for security
- Independent scaling per service
- Easy rollbacks with `docker stack` commands

Deploy manually via SSH:
```bash
ssh -p 1923 deployer@<droplet-ip>
docker stack deploy -c docker-compose.yml my-app
```

Or integrate with your preferred CI/CD pipeline.

## Security

- **Non-Standard SSH Port:** SSH runs on port 1923 (not 22)
- **SSH Key Authentication:** No password authentication
- **Root SSH Disabled:** Only the deployer user can SSH in (with sudo access)
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
- **Terraform fails?** Verify API tokens and Terraform Cloud setup
- **Service won't start?** Check logs with `docker service logs`
- **Out of space?** Run `docker system prune -a`

## License

MIT License - See [LICENSE](LICENSE) file

## Roadmap

Future enhancements:
- [ ] Deployment workflows and CI/CD integration examples
- [ ] Traefik for automatic SSL and routing
- [ ] Automated backups to DigitalOcean Spaces
- [ ] Multi-region support
- [ ] Database templates (Postgres, Redis, MongoDB)
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
