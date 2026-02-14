# Security Configuration Summary

This document outlines the security configuration implemented for CloudLab infrastructure.

## Network Security

### Firewall Rules (Inbound)

Only the following ports are exposed to the public internet:

**TCP Ports:**
- **1923** - SSH (non-standard port for security)
- **80** - HTTP
- **443** - HTTPS
- **8081** - Custom application port

**UDP Ports:**
- **443** - HTTPS/HTTP3 (QUIC protocol)

**All other ports are blocked by default.**

### SSH Hardening

1. **Non-Standard Port**: SSH runs on port 1923 instead of the default port 22
   - Reduces automated scanning and brute-force attempts
   - Makes the server less visible to port scanners

2. **Key-Based Authentication**: Only SSH key authentication is allowed
   - No password authentication
   - Keys must be pre-configured in Terraform

3. **Fail2ban**: Automatic IP banning after failed login attempts
   - Protects against brute-force attacks
   - Configured automatically via cloud-init

4. **UFW Firewall**: Host-based firewall in addition to DigitalOcean firewall
   - Defense in depth strategy
   - Configured to allow only specified ports

### Why No IP Whitelisting?

IP whitelisting has been **intentionally disabled** because:
- No static IP address is available for the administrator
- Dynamic IPs change frequently
- Would risk lockout if IP changes unexpectedly

**Compensating controls:**
- Non-standard SSH port (port 1923)
- Key-based authentication only
- Fail2ban for brute-force protection
- Strong SSH keys (ed25519 recommended)

## Infrastructure Security

### Region

**Default Region: fra1 (Frankfurt)**
- EU-based data center
- GDPR compliant
- Low latency for European users

### Operating System

**Ubuntu 24.04 LTS**
- Latest LTS release with long-term support
- Regular security updates
- Automatic security updates enabled via unattended-upgrades

### Docker Swarm Ports

Docker Swarm management ports (2377, 7946, 4789) are **NOT exposed** to the public internet:
- Only accessible from localhost
- Single-node setup doesn't require external swarm communication
- If scaling to multi-node, use private networking or VPN

## Application Security

### Secrets Management

1. **GitHub Secrets** for CI/CD credentials:
   - `SWARM_HOST` - Droplet IP address
   - `SWARM_SSH_KEY` - Private SSH key for deployer
   - `SWARM_SSH_PORT` - SSH port (1923)
   - `SWARM_USER` - Username (deployer)

2. **Docker Secrets** for application secrets:
   - Stored encrypted in swarm
   - Only accessible to services that need them
   - Never stored in environment variables or compose files

### Container Registry

**GitHub Container Registry (GHCR)**
- Private by default
- Authentication required for pulls
- Integrated with GitHub Actions

### User Accounts

**Two user accounts:**
1. **root** - System administration (emergency access)
2. **deployer** - CI/CD deployments (limited sudo access)

Both require SSH key authentication.

## Security Best Practices

### For Administrators

1. **Protect your SSH private key**
   ```bash
   chmod 600 ~/.ssh/id_ed25519
   ```

2. **Use strong passphrases** for SSH keys

3. **Keep your local SSH config updated**
   ```
   Host cloudlab
       HostName YOUR_DROPLET_IP
       Port 1923
       User deployer
       IdentityFile ~/.ssh/cloudlab_deployer
   ```

4. **Regularly rotate SSH keys**
   - Update Terraform variables
   - Run `terraform apply`

5. **Monitor system logs**
   ```bash
   ssh -p 1923 deployer@YOUR_IP
   sudo journalctl -u ssh -f
   sudo fail2ban-client status sshd
   ```

### For Developers

1. **Never commit secrets** to git repositories

2. **Use environment variables** for configuration

3. **Scan images** for vulnerabilities before deploying

4. **Keep base images updated**
   ```dockerfile
   FROM node:20-alpine  # Use specific versions
   ```

5. **Run containers as non-root** when possible
   ```dockerfile
   USER node
   ```

## Security Monitoring

### System-Level

- **fail2ban** monitors SSH authentication attempts
- **UFW** logs blocked connection attempts
- **unattended-upgrades** automatically installs security updates

### Application-Level

- **Grafana Alloy** collects logs from all containers
- Logs can be sent to Grafana Cloud for analysis
- Set up alerts for suspicious activity

### Check Security Status

```bash
# SSH to droplet
ssh -p 1923 deployer@YOUR_IP

# Check firewall status
sudo ufw status verbose

# Check fail2ban status
sudo fail2ban-client status

# Check banned IPs
sudo fail2ban-client status sshd

# View recent SSH attempts
sudo journalctl -u ssh --since "1 hour ago"

# Check for security updates
sudo apt update
sudo apt list --upgradable
```

## Emergency Procedures

### Locked Out of SSH?

1. Access via DigitalOcean Console (web-based terminal)
2. Check SSH service: `systemctl status sshd`
3. Check firewall: `ufw status`
4. Check SSH port: `grep Port /etc/ssh/sshd_config`
5. Check fail2ban: `fail2ban-client status sshd`

### Compromised Server?

1. **Immediately** change all SSH keys:
   ```bash
   cd terraform
   # Update ssh_public_key_path and deployer_ssh_public_key
   terraform apply
   ```

2. Rotate all secrets in GitHub

3. Review logs for unauthorized access:
   ```bash
   sudo journalctl -u ssh --since "24 hours ago"
   sudo lastlog
   sudo last
   ```

4. Consider rebuilding the infrastructure:
   ```bash
   terraform destroy
   terraform apply
   ```

### Under Attack?

1. **Enable rate limiting** in fail2ban (if not already enabled)

2. **Temporarily restrict SSH** to your current IP:
   ```bash
   # Get your IP
   MY_IP=$(curl -s ifconfig.me)
   
   # Allow only your IP
   sudo ufw delete allow 1923/tcp
   sudo ufw allow from $MY_IP/32 to any port 1923 proto tcp
   ```

3. **Review attack logs**:
   ```bash
   sudo journalctl -u ssh --since "1 hour ago" | grep Failed
   sudo fail2ban-client status sshd
   ```

4. **Block specific IPs** if needed:
   ```bash
   sudo ufw deny from ATTACKER_IP
   ```

## Compliance Notes

### GDPR Considerations

- Data center located in Frankfurt (EU)
- Server logs contain IP addresses (personal data)
- Grafana Cloud may store logs outside EU (configure accordingly)
- Consider adding a privacy policy if collecting user data

### Audit Trail

All administrative actions should be logged:
- Terraform changes are tracked in git
- GitHub Actions logs show deployment history
- System logs capture SSH access and commands

## Security Updates

### Automatic Updates

Ubuntu is configured to automatically install security updates:
- Enabled via `unattended-upgrades`
- Runs daily
- Only installs security patches (not all updates)

### Manual Updates

For major system updates:

```bash
ssh -p 1923 deployer@YOUR_IP
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade  # For major version upgrades
```

### Docker Updates

Update Docker images regularly:

```bash
# In your project
docker pull node:20-alpine
docker build --no-cache -t myapp .
git commit -am "Update base image"
git push  # Triggers automatic deployment
```

## Security Checklist

Before going to production:

- [ ] Changed SSH to non-standard port (1923)
- [ ] SSH key authentication only (no passwords)
- [ ] Strong SSH keys generated (ed25519)
- [ ] Fail2ban is running
- [ ] UFW firewall is enabled
- [ ] Only necessary ports are open
- [ ] Automatic security updates enabled
- [ ] Monitoring is set up (Grafana Alloy)
- [ ] GitHub Secrets are configured
- [ ] Docker secrets used for sensitive data
- [ ] Container images are from trusted sources
- [ ] Regular backup strategy in place
- [ ] Emergency access procedure documented

## Additional Recommendations

For production workloads, consider:

1. **VPN Access** for SSH (e.g., Tailscale, WireGuard)
2. **2FA** for DigitalOcean account
3. **Regular security audits** and penetration testing
4. **Separate staging/production** environments
5. **Database backups** to DigitalOcean Spaces
6. **WAF** (Web Application Firewall) via Cloudflare
7. **DDoS protection** via Cloudflare or DO's offering
8. **Security scanning** of Docker images (Trivy, Snyk)
9. **Intrusion detection** (OSSEC, Wazuh)
10. **Compliance scanning** (OpenSCAP)

## References

- [DigitalOcean Security Best Practices](https://docs.digitalocean.com/products/security/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [Ubuntu Security Guide](https://ubuntu.com/security)
- [fail2ban Documentation](https://www.fail2ban.org/)
- [UFW Documentation](https://help.ubuntu.com/community/UFW)
