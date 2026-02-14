# CloudLab Setup Guide

This guide will walk you through setting up the CloudLab infrastructure from scratch.

## Security Notice

CloudLab is configured with enhanced security:
- **SSH on port 1923** (non-standard port for security)
- **Ubuntu 24.04 LTS** (latest LTS release)
- **Region: Frankfurt (fra1)** by default
- **Firewall**: Only ports 1923, 80, 443, 8081 (TCP) and 443 (UDP) are exposed
- **No IP whitelisting**: No static IP required

See [SECURITY.md](./SECURITY.md) for detailed security information.

## Prerequisites

Before you begin, ensure you have:

1. **DigitalOcean Account**
   - Sign up at [digitalocean.com](https://www.digitalocean.com/)
   - Generate an API token: Account → API → Generate New Token
   - Save the token securely (starts with `dop_v1_`)

2. **Terraform Cloud Account**
   - Sign up at [app.terraform.io](https://app.terraform.io/)
   - Create an organization (or use an existing one)
   - Generate an API token: User Settings → Tokens → Create an API token

3. **GitHub Account**
   - You'll need admin access to this repository
   - Ability to add secrets and configure workflows

4. **SSH Keys**
   - Generate SSH keys for accessing the droplet
   - Optionally, generate a separate key for CI/CD deployments

5. **Local Tools**
   - Terraform CLI (>= 1.0) - [Install Guide](https://developer.hashicorp.com/terraform/install)
   - Git
   - SSH client

## Step 1: Generate SSH Keys

If you don't already have SSH keys, generate them:

```bash
# Main SSH key for your access
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519

# Optional: Separate key for GitHub Actions deployments
ssh-keygen -t ed25519 -C "cloudlab-deployer" -f ~/.ssh/cloudlab_deployer
```

## Step 2: Configure Terraform Cloud

1. Log in to [Terraform Cloud](https://app.terraform.io/)
2. Create a new organization (if you don't have one)
3. Note your organization name
4. Create a workspace named `cloudlab-infrastructure` (or choose your own name)
5. Generate an API token:
   - Click your user icon → User Settings → Tokens
   - Create an API token and save it securely

## Step 3: Update Terraform Backend Configuration

Edit `terraform/providers.tf` and update the Terraform Cloud configuration:

```hcl
cloud {
  organization = "YOUR_ORG_NAME_HERE"  # Replace with your org name

  workspaces {
    name = "cloudlab-infrastructure"  # Or your workspace name
  }
}
```

## Step 4: Authenticate Terraform CLI

Log in to Terraform Cloud from your terminal:

```bash
terraform login
```

This will open a browser window. Generate a token and paste it into the terminal.

## Step 5: Configure Terraform Variables

1. Copy the example variables file:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your values:

```hcl
# DigitalOcean API token
do_token = "dop_v1_your_token_here"

# Region (see: https://slugs.do-api.dev/)
do_region = "fra1"  # Frankfurt, Germany (default)

# SSH port (non-standard for security)
ssh_port = 1923

# Droplet configuration
droplet_size = "s-1vcpu-2gb"  # $12/mo
droplet_name = "cloudlab-swarm"

# SSH keys
ssh_public_key_path  = "~/.ssh/id_ed25519.pub"
ssh_private_key_path = "~/.ssh/id_ed25519"

# Optional: Separate deployer key for GitHub Actions
deployer_ssh_public_key = "ssh-ed25519 AAAAC3... cloudlab-deployer"

# Optional: Grafana Cloud configuration
grafana_cloud_endpoint  = ""  # Fill if you have Grafana Cloud
grafana_cloud_username  = ""
grafana_cloud_api_key   = ""
```

⚠️ **Important:** Never commit `terraform.tfvars` to git! It's already in `.gitignore`.

## Step 6: Initialize Terraform

```bash
cd terraform
terraform init
```

This will:
- Download the DigitalOcean provider
- Configure the Terraform Cloud backend
- Prepare your workspace

## Step 7: Plan the Infrastructure

Review what Terraform will create:

```bash
terraform plan
```

You should see:
- 1 SSH key resource
- 1 Droplet resource
- 1 Firewall resource
- Various data sources

## Step 8: Apply the Infrastructure

Create the infrastructure:

```bash
terraform apply
```

Type `yes` when prompted. This will:
- Create a DigitalOcean droplet
- Set up firewall rules
- Install Docker and initialize Swarm
- Deploy Grafana Alloy
- Create a deployer user

⏱️ This takes about 5-10 minutes.

## Step 9: Verify the Deployment

After Terraform completes, you'll see outputs:

```
Outputs:

droplet_ip = "164.90.xxx.xxx"
droplet_name = "cloudlab-swarm"
ssh_port = 1923
ssh_connection_string = "ssh -p 1923 root@164.90.xxx.xxx"
deployer_connection_string = "ssh -p 1923 deployer@164.90.xxx.xxx"
```

Test SSH access:

```bash
# As root
ssh -p 1923 root@<your-droplet-ip>

# As deployer user
ssh -p 1923 deployer@<your-droplet-ip>
```

## Step 10: Verify Docker Swarm

Once connected, verify the swarm is running:

```bash
# Check swarm status
docker node ls

# List running services
docker service ls

# Check Grafana Alloy
docker service logs monitoring_alloy
```

## Step 11: Configure GitHub Secrets

Your project repositories need these secrets to deploy:

1. Go to your project repository
2. Settings → Secrets and variables → Actions
3. Add these secrets:

```
SWARM_HOST = <your-droplet-ip>
SWARM_SSH_KEY = <contents of ~/.ssh/cloudlab_deployer (private key)>
SWARM_SSH_PORT = 1923
SWARM_USER = deployer
```

**Note:** The `SWARM_SSH_PORT` defaults to 1923 if not provided, but it's good practice to set it explicitly.

## Step 12: Configure GitHub Actions in CloudLab Repo

Add these secrets to the CloudLab repository:

1. Settings → Secrets and variables → Actions
2. Add repository secrets:

```
DO_TOKEN = <your-digitalocean-api-token>
TF_API_TOKEN = <your-terraform-cloud-api-token>
```

## Step 13: (Optional) Configure Grafana Alloy

If you have a Grafana Cloud account:

1. SSH into the droplet
2. Edit the Alloy configuration:

```bash
sudo vi /tmp/alloy-config.alloy
```

3. Update the URLs and credentials:

```hcl
loki.write "default" {
  endpoint {
    url = "https://logs-prod-us-central1.grafana.net/loki/api/v1/push"
    basic_auth {
      username = "123456"
      password = "glc_xxxxx"
    }
  }
}
```

4. Restart the Alloy service:

```bash
docker service update --force monitoring_alloy
```

## Troubleshooting

### Terraform fails with authentication error

```bash
# Re-authenticate with Terraform Cloud
terraform login

# Or set the token manually
export TF_TOKEN_app_terraform_io="your-token"
```

### Cannot SSH to droplet

1. Wait 5-10 minutes for cloud-init to complete and SSH port to change

2. Verify you're using the correct port:
   ```bash
   ssh -p 1923 root@<droplet-ip>
   ```

3. Verify SSH key is correct:
   ```bash
   ssh-add -l  # List loaded keys
   ssh-add ~/.ssh/id_ed25519  # Add your key
   ```

4. Check DigitalOcean firewall allows port 1923

5. If still unable to connect, use DigitalOcean Console (web-based terminal)

### Cloud-init didn't complete

SSH to the droplet and check cloud-init status:

```bash
cloud-init status --wait
journalctl -u cloud-init -f
```

### Docker Swarm not initialized

Manually initialize:

```bash
sudo /usr/local/bin/init-swarm.sh
```

## Next Steps

Now that your infrastructure is set up:

1. Review [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues
2. Check [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) for useful commands
3. Start deploying your services to the swarm using `docker stack deploy`

## Cost Estimate

- **Droplet (s-1vcpu-2gb):** $12/month
- **Terraform Cloud:** Free tier (up to 500 resources)
- **DigitalOcean Bandwidth:** 2TB included, then $0.01/GB
- **Grafana Cloud:** Free tier (14-day retention)

**Total:** ~$12/month

## Scaling Up

When you need more resources:

1. Update `droplet_size` in `terraform.tfvars`
2. Run `terraform apply`
3. DigitalOcean will resize the droplet (brief downtime)

Or add more nodes:

1. Duplicate the droplet resource in `terraform/droplet.tf`
2. On new nodes, join the swarm as workers
3. Update firewall rules to allow inter-node communication

## Destroying the Infrastructure

⚠️ **Warning:** This will delete everything!

```bash
cd terraform
terraform destroy
```

Type `yes` to confirm. This will:
- Delete the droplet (and all data on it)
- Remove firewall rules
- Delete SSH keys from DigitalOcean

Your Terraform state remains in Terraform Cloud.
