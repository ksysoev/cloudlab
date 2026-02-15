# CloudLab Ansible Configuration

This directory contains Ansible playbooks and roles for configuring the CloudLab infrastructure. The configuration is idempotent and can be safely run multiple times without recreating the droplet.

## Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventory/
│   └── production.py        # Dynamic inventory (fetches from Terraform)
├── group_vars/
│   └── all.yml              # Default variables
├── playbooks/
│   └── site.yml             # Main playbook
└── roles/
    ├── common/              # Base system configuration
    ├── security/            # Firewall, SSH hardening, fail2ban
    ├── docker/              # Docker CE, Swarm, daemon config
    └── monitoring/          # Grafana Alloy monitoring
```

## Requirements

- Ansible >= 2.14
- Python 3
- Terraform (for dynamic inventory)
- SSH access to the droplet

Install required Ansible collections:
```bash
ansible-galaxy collection install community.general
```

## Usage

### Run full configuration
```bash
cd ansible
ansible-playbook playbooks/site.yml
```

### Run specific roles
```bash
# Only security configuration
ansible-playbook playbooks/site.yml --tags security

# Only Docker and Swarm
ansible-playbook playbooks/site.yml --tags docker

# Only monitoring
ansible-playbook playbooks/site.yml --tags monitoring
```

### Check mode (dry run)
```bash
ansible-playbook playbooks/site.yml --check --diff
```

## Variables

Variables are defined in `group_vars/all.yml`. Override them via:

1. **Extra vars** (highest priority):
   ```bash
   ansible-playbook playbooks/site.yml -e "ssh_port=2222"
   ```

2. **Environment variables** (for sensitive data):
   ```bash
   export GRAFANA_CLOUD_API_KEY="your-key"
   ansible-playbook playbooks/site.yml -e "grafana_cloud_api_key=${GRAFANA_CLOUD_API_KEY}"
   ```

### Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ssh_port` | 1923 | SSH port |
| `swarm_instance_name` | cloudlab-swarm | Instance identifier |
| `grafana_cloud_logs_url` | "" | Grafana Cloud Loki endpoint |
| `grafana_cloud_logs_id` | "" | Loki instance ID |
| `grafana_cloud_metrics_url` | "" | Grafana Cloud Prometheus endpoint |
| `grafana_cloud_metrics_id` | "" | Prometheus instance ID |
| `grafana_cloud_api_key` | "" | Grafana Cloud API key |

## CI/CD Integration

The playbook is automatically run by GitHub Actions after Terraform provisions infrastructure. See `.github/workflows/configure.yml`.

### Required GitHub Secrets

The workflow needs these secrets configured in your repository:

**Required:**
- `TF_API_TOKEN` - Terraform Cloud API token (for dynamic inventory)
- `SSH_PRIVATE_KEY` - SSH private key to connect to the droplet

**Optional (with defaults):**
- `SWARM_USER` - SSH username (default: `deployer`)
- `SWARM_SSH_PORT` - SSH port (default: `1923`)

**Optional (for monitoring):**
- `GRAFANA_CLOUD_LOGS_URL` - Grafana Cloud Loki push endpoint
- `GRAFANA_CLOUD_LOGS_ID` - Loki instance ID
- `GRAFANA_CLOUD_METRICS_URL` - Grafana Cloud Prometheus push endpoint
- `GRAFANA_CLOUD_METRICS_ID` - Prometheus instance ID
- `GRAFANA_CLOUD_API_KEY` - Grafana Cloud API key

These secrets are passed as extra vars to the playbook during CI/CD runs.

## Migration from cloud-init

This Ansible configuration replaces the monolithic `terraform/cloud-init.yaml`. The main benefits:

- **Idempotent**: Changes don't recreate the droplet
- **Stateful**: Safe for production workloads
- **Modular**: Each role is independently testable
- **Version controlled**: Easy to track changes and rollback
