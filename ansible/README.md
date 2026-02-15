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

- Ansible >= 8.0.0 (includes ansible-core >= 2.15.0)
- Python 3.9+
- Terraform (for dynamic inventory)
- SSH access to the droplet

### Installation

This project uses [Poetry](https://python-poetry.org/) for dependency management, which provides lock file support for reproducible builds and Dependabot compatibility.

Install Poetry:
```bash
curl -sSL https://install.python-poetry.org | python3 -
```

Install dependencies:
```bash
# Install all dependencies (including test dependencies)
poetry install

# Install production dependencies only
poetry install --only main

# Install Ansible Galaxy collections
ansible-galaxy install -r requirements.yml
```

**Note:** CI/CD workflows currently use pip with `requirements.txt` files for simplicity and faster execution. The `poetry.lock` file is primarily for local development reproducibility and Dependabot vulnerability tracking.

### Legacy Installation (pip)

Alternatively, you can use pip with requirements.txt files:
```bash
# Install Ansible and runtime requirements
pip install -r requirements.txt

# Install Ansible Galaxy collections
ansible-galaxy install -r requirements.yml
```

For testing and development:
```bash
pip install -r requirements-test.txt
```

## Usage

### Activate Poetry environment

If using Poetry, activate the virtual environment:
```bash
poetry shell
```

Or run commands directly with Poetry:
```bash
poetry run ansible-playbook playbooks/site.yml
```

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

## Testing

The Ansible roles are tested using [Molecule](https://molecule.readthedocs.io/) with Docker and [Testinfra](https://testinfra.readthedocs.io/) for verification.

### Running Tests Locally

Use the provided test script to run all tests:

```bash
cd ansible

# Run linting only
./test.sh lint

# Run Molecule tests for all roles
./test.sh all

# Run everything (lint + molecule)
./test.sh
```

### Running Tests for Individual Roles

```bash
cd ansible/roles/common
molecule test

cd ../security
molecule test

cd ../docker
molecule test

cd ../monitoring
molecule test
```

### Test Coverage

Each role has comprehensive tests:

- **common**: Package installation, directory creation, auto-updates
- **security**: UFW configuration, fail2ban, SSH hardening
- **docker**: Docker installation, Swarm initialization, daemon config
- **monitoring**: Grafana Alloy installation, configuration files, service status

### CI/CD Testing

Tests run automatically on every push and pull request via GitHub Actions. See `.github/workflows/test-ansible.yml`.

The workflow runs:
1. `ansible-lint` - Checks Ansible best practices
2. `yamllint` - Validates YAML syntax
3. `molecule test` - Tests each role in isolated Docker containers

## Migration from cloud-init

This Ansible configuration replaces the monolithic `terraform/cloud-init.yaml`. The main benefits:

- **Idempotent**: Changes don't recreate the droplet
- **Stateful**: Safe for production workloads
- **Modular**: Each role is independently testable
- **Version controlled**: Easy to track changes and rollback
