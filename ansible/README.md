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

## Migration from cloud-init

This Ansible configuration replaces the monolithic `terraform/cloud-init.yaml`. The main benefits:

- **Idempotent**: Changes don't recreate the droplet
- **Stateful**: Safe for production workloads
- **Modular**: Each role is independently testable
- **Version controlled**: Easy to track changes and rollback
