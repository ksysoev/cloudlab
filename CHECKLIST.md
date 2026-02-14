# CloudLab Pre-Flight Checklist

Use this checklist before deploying CloudLab infrastructure for the first time.

## Prerequisites Checklist

### Accounts

- [ ] DigitalOcean account created
- [ ] DigitalOcean API token generated (starts with `dop_v1_`)
- [ ] Terraform Cloud account created
- [ ] Terraform Cloud organization created
- [ ] Terraform Cloud API token generated
- [ ] GitHub account with repo access

### Local Setup

- [ ] Terraform CLI installed (>= 1.0)
- [ ] Git installed
- [ ] SSH keys generated
- [ ] SSH client available
- [ ] CloudLab repository cloned

### Configuration Files

- [ ] `terraform/providers.tf` updated with your Terraform Cloud organization name
- [ ] `terraform/terraform.tfvars` created from example
- [ ] `terraform/terraform.tfvars` filled with your values:
  - [ ] `do_token` (DigitalOcean API token)
  - [ ] `do_region` (e.g., "nyc3")
  - [ ] `droplet_size` (e.g., "s-1vcpu-2gb")
  - [ ] `ssh_public_key_path` (path to your public key)
  - [ ] `ssh_private_key_path` (path to your private key)
  - [ ] `deployer_ssh_public_key` (optional, for separate CI/CD key)

### GitHub Secrets (CloudLab Repo)

- [ ] `DO_TOKEN` added (for provision workflow)
- [ ] `TF_API_TOKEN` added (for provision workflow)

## Infrastructure Deployment Checklist

### Terraform Initialization

```bash
cd terraform
terraform login
terraform init
```

- [ ] Terraform Cloud authentication successful
- [ ] Backend initialized successfully
- [ ] Providers downloaded

### Terraform Planning

```bash
terraform plan
```

- [ ] Plan runs without errors
- [ ] Resources to create:
  - [ ] 1 SSH key
  - [ ] 1 Droplet
  - [ ] 1 Firewall
- [ ] No unexpected changes

### Terraform Apply

```bash
terraform apply
```

- [ ] Apply completes successfully
- [ ] Outputs displayed:
  - [ ] droplet_ip
  - [ ] droplet_name
  - [ ] ssh_connection_string
  - [ ] deployer_connection_string

### Verify Infrastructure

```bash
# Get droplet IP
terraform output droplet_ip

# SSH to droplet (may take 5-10 minutes for cloud-init to complete)
ssh root@<droplet-ip>
```

- [ ] Can SSH to droplet as root
- [ ] Can SSH to droplet as deployer
- [ ] Docker is installed (`docker --version`)
- [ ] Docker Swarm is active (`docker info | grep Swarm`)
- [ ] Swarm has 1 manager node (`docker node ls`)

### Verify Services

On the droplet:

```bash
# Check running services
docker service ls

# Check Grafana Alloy (if configured)
docker service ps monitoring_alloy
docker service logs monitoring_alloy
```

- [ ] Alloy service is running (if Grafana Cloud configured)
- [ ] No error messages in logs

## First Project Deployment Checklist

### Project Repository Setup

- [ ] Project has a Dockerfile
- [ ] Project has a docker-compose.yml
- [ ] Workflow file created at `.github/workflows/deploy.yml`
- [ ] Workflow references correct CloudLab repo (update `YOUR_USERNAME`)

### GitHub Secrets (Project Repo)

- [ ] `SWARM_HOST` added (droplet IP from `terraform output`)
- [ ] `SWARM_SSH_KEY` added (deployer private key)
- [ ] `SWARM_USER` added (value: `deployer`)

### Deployment

```bash
git add .
git commit -m "Add deployment workflow"
git push origin main
```

- [ ] GitHub Actions workflow triggered
- [ ] Build step completes successfully
- [ ] Image pushed to GHCR
- [ ] Stack deployed to swarm
- [ ] Services are running

### Verify Deployment

```bash
# SSH to droplet
ssh deployer@<droplet-ip>

# Check stack
docker stack ls
docker stack services <stack-name>
docker stack ps <stack-name>

# Check logs
docker service logs <stack-name>_<service-name>
```

- [ ] Stack is listed
- [ ] Services show replicas running (e.g., 2/2)
- [ ] No error messages in logs
- [ ] Can access service (if it exposes a port)

## Common Issues

### Terraform apply fails

**"unauthorized" error:**
- Verify `do_token` in `terraform.tfvars`
- Ensure token has write permissions

**"timeout" error:**
- Check DigitalOcean status page
- Try a different region
- Verify account isn't at resource limits

### Cannot SSH to droplet

**"connection refused":**
- Wait 5-10 minutes for cloud-init to complete
- Check firewall allows your IP (`allowed_ssh_ips`)
- Verify SSH key is correct

**"permission denied":**
- Ensure SSH key is loaded (`ssh-add ~/.ssh/id_ed25519`)
- Verify public key matches private key
- Check key was added to Terraform config

### GitHub Actions deployment fails

**"permission denied" on SSH:**
- Verify `SWARM_SSH_KEY` is the PRIVATE key (not .pub)
- Check key format includes BEGIN/END markers
- Ensure no extra whitespace in secret

**"unable to resolve image":**
- Verify image was built and pushed
- Check GHCR package exists
- Ensure image name in compose file matches

**Stack deploys but service won't start:**
- Check service logs: `docker service logs <service-name>`
- Verify port isn't already in use
- Check resource constraints
- Ensure image can be pulled

## Maintenance Checklist

### Weekly

- [ ] Check disk usage: `docker system df`
- [ ] Review service logs for errors
- [ ] Verify all services are running

### Monthly

- [ ] Clean up unused Docker resources: `docker system prune -a`
- [ ] Review Grafana Cloud usage (if using)
- [ ] Update OS packages: `apt update && apt upgrade`

### As Needed

- [ ] Scale services based on load
- [ ] Update Terraform configuration
- [ ] Add new projects
- [ ] Review and rotate SSH keys

## Emergency Procedures

### Service is down

1. SSH to droplet
2. Check service status: `docker service ps <service-name> --no-trunc`
3. Check logs: `docker service logs <service-name>`
4. Restart if needed: `docker service update --force <service-name>`

### Out of disk space

1. SSH to droplet
2. Check usage: `df -h && docker system df`
3. Clean up: `docker system prune -a --volumes`

### Droplet is unresponsive

1. Access DigitalOcean console
2. Use Recovery Console to access droplet
3. Check logs: `journalctl -u docker`
4. Reboot if necessary (from DO dashboard)

### Need to rebuild infrastructure

1. Backup important volumes first
2. Run: `terraform destroy`
3. Wait for resources to be deleted
4. Run: `terraform apply`
5. Redeploy all stacks

## Success Criteria

Your CloudLab deployment is successful when:

- ✅ Infrastructure is provisioned and accessible
- ✅ Docker Swarm is running with 1 manager node
- ✅ Can deploy projects via GitHub Actions
- ✅ Services are accessible from the internet
- ✅ Monitoring is collecting logs/metrics (if configured)
- ✅ No errors in service logs
- ✅ Documentation is clear and helpful

## Support

If you encounter issues not covered here:

1. Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Review [SETUP.md](docs/SETUP.md)
3. Check GitHub Actions logs
4. SSH to droplet and investigate
5. Open a GitHub issue with details

## Notes

- First cloud-init run takes 5-10 minutes
- Droplet resize requires brief downtime
- Always backup before major changes
- Test deployments in a staging stack first
- Monitor costs in DigitalOcean dashboard

---

**Ready to deploy?** Start with `terraform apply` in the `terraform/` directory!
