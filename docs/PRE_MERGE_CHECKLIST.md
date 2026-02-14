# Pre-Merge Checklist

Before merging this PR and provisioning your infrastructure, ensure all prerequisites are completed.

## ✅ GitHub Configuration

### CloudLab Repository Secrets

Go to **Settings → Secrets and variables → Actions** in this repository and add:

- [ ] `TF_API_TOKEN` - Your Terraform Cloud API token
  - Get from: https://app.terraform.io/app/settings/tokens
  - Required for: GitHub Actions to run Terraform commands
  
- [ ] `DO_TOKEN` - Your DigitalOcean API token
  - Get from: https://cloud.digitalocean.com/account/api/tokens
  - Required for: Terraform to provision infrastructure
  - Format: `dop_v1_...`

### Verify GitHub Actions is Enabled

- [ ] Go to **Settings → Actions → General**
- [ ] Ensure "Allow all actions and reusable workflows" is selected
- [ ] Save if you made changes

## ✅ Terraform Cloud Setup

- [ ] Created account at https://app.terraform.io/
- [ ] Created organization (note the name)
- [ ] Created workspace named `cloudlab-infrastructure` (or your chosen name)
- [ ] Updated `terraform/providers.tf` with your organization name:
  ```hcl
  cloud {
    organization = "YOUR_ORG_NAME_HERE"  # ← Update this!
  }
  ```

## ✅ DigitalOcean Setup

- [ ] Created account at https://www.digitalocean.com/
- [ ] Generated API token (Personal Access Token)
- [ ] Token has **read and write** permissions
- [ ] Saved token securely (you'll only see it once)

## ✅ SSH Keys Prepared

- [ ] Generated SSH key pair for personal access
  ```bash
  ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519
  ```

- [ ] Generated separate SSH key pair for GitHub Actions (recommended)
  ```bash
  ssh-keygen -t ed25519 -C "cloudlab-deployer" -f ~/.ssh/cloudlab_deployer
  ```

- [ ] Public keys are ready (`.pub` files)
- [ ] Private keys are kept secure (never commit these!)

## ✅ Local Configuration

- [ ] Terraform CLI installed (>= 1.0)
  ```bash
  terraform version
  ```

- [ ] Authenticated with Terraform Cloud
  ```bash
  terraform login
  ```

- [ ] Copied example variables file
  ```bash
  cd terraform
  cp terraform.tfvars.example terraform.tfvars
  ```

- [ ] Edited `terraform.tfvars` with your values:
  - [ ] `do_token` - Your DigitalOcean API token
  - [ ] `do_region` - Your preferred region (default: `fra1`)
  - [ ] `ssh_port` - SSH port number (default: `1923`)
  - [ ] `droplet_name` - Name for your droplet
  - [ ] `droplet_size` - Droplet size (default: `s-1vcpu-2gb`)
  - [ ] `ssh_public_key_path` - Path to your public key
  - [ ] `ssh_private_key_path` - Path to your private key
  - [ ] `deployer_ssh_public_key` - Public key for GitHub Actions

- [ ] Verified `terraform.tfvars` is in `.gitignore` (it should be!)

## ✅ Documentation Review

- [ ] Read [SETUP.md](./SETUP.md) - Understand the setup process
- [ ] Read [SECURITY.md](./SECURITY.md) - Understand security configuration
- [ ] Read [DEPLOYMENT.md](./DEPLOYMENT.md) - Know how to deploy projects
- [ ] Bookmarked [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - For when issues arise

## ✅ Cost Awareness

- [ ] Understand the monthly cost (~$12-15/month for base setup)
- [ ] Know how to destroy infrastructure to stop costs:
  ```bash
  cd terraform
  terraform destroy
  ```

## ✅ Security Understanding

- [ ] SSH will run on port **1923** (not standard port 22)
- [ ] Only these ports will be exposed:
  - TCP: 1923 (SSH), 80 (HTTP), 443 (HTTPS), 8081 (custom)
  - UDP: 443 (HTTP/3)
- [ ] Ubuntu 24.04 LTS with automatic security updates
- [ ] UFW firewall configured for defense in depth
- [ ] Fail2ban installed for brute-force protection
- [ ] No IP whitelisting (SSH protected by non-standard port + key auth)

## ✅ Post-Merge Steps Planned

After merging, you'll need to:

1. [ ] Run Terraform locally to provision infrastructure:
   ```bash
   cd terraform
   terraform init
   terraform plan    # Review changes
   terraform apply   # Create infrastructure
   ```

2. [ ] Save the droplet IP from Terraform outputs

3. [ ] Wait 5-10 minutes for cloud-init to complete

4. [ ] Test SSH access:
   ```bash
   ssh -p 1923 root@<droplet-ip>
   ssh -p 1923 deployer@<droplet-ip>
   ```

5. [ ] Verify Docker Swarm is running:
   ```bash
   docker node ls
   docker service ls
   ```

6. [ ] Configure project repositories with secrets:
   - `SWARM_HOST` - Droplet IP
   - `SWARM_SSH_KEY` - Private key content (from `~/.ssh/cloudlab_deployer`)
   - `SWARM_SSH_PORT` - 1923
   - `SWARM_USER` - deployer

## ✅ Rollback Plan

If something goes wrong:

- [ ] Know how to access DigitalOcean Console (web-based terminal):
  - Go to: https://cloud.digitalocean.com/droplets
  - Click on your droplet → Access → Launch Droplet Console

- [ ] Know how to destroy and recreate:
  ```bash
  terraform destroy
  # Fix issues
  terraform apply
  ```

- [ ] Have your SSH keys backed up securely

## 🚀 Ready to Merge?

Once all checkboxes are complete:

1. ✅ All prerequisites met
2. ✅ All configurations prepared
3. ✅ Documentation reviewed
4. ✅ Ready to provision infrastructure

**You're ready to merge the PR!**

After merging:
1. Switch to `main` branch: `git checkout main && git pull`
2. Follow post-merge steps above
3. Start deploying services to your swarm cluster!

## 📝 Notes

- The GitHub Actions workflow will fail on the PR until you add the secrets - this is expected
- You can merge the PR even with failed checks - they'll pass once secrets are configured
- The first `terraform apply` takes 5-10 minutes due to cloud-init setup
- Keep your `terraform.tfvars` file secure and never commit it to git
- Store your SSH private keys securely (use a password manager)

## ❓ Need Help?

- Review [SETUP.md](./SETUP.md) for detailed instructions
- Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues
- Review [SECURITY.md](./SECURITY.md) for security questions

## 🎯 Quick Command Reference

```bash
# Terraform commands (run in terraform/ directory)
terraform init      # Initialize Terraform
terraform plan      # Preview changes
terraform apply     # Create infrastructure
terraform destroy   # Destroy everything
terraform output    # Show outputs (IP, connection strings)

# SSH commands (after provisioning)
ssh -p 1923 root@<ip>      # Connect as root
ssh -p 1923 deployer@<ip>  # Connect as deployer

# Docker Swarm commands (on droplet)
docker node ls             # List nodes
docker service ls          # List services
docker stack ls            # List stacks
docker service logs <svc>  # View service logs
```

---

**Ready? Let's deploy!** 🚀
