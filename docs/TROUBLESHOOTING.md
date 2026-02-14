# Troubleshooting Guide

Common issues and solutions for CloudLab infrastructure and deployments.

## Table of Contents

- [Infrastructure Issues](#infrastructure-issues)
- [SSH and Connection Problems](#ssh-and-connection-problems)
- [Deployment Failures](#deployment-failures)
- [Service Issues](#service-issues)
- [Networking Problems](#networking-problems)
- [Performance Issues](#performance-issues)
- [Monitoring and Logs](#monitoring-and-logs)

## Infrastructure Issues

### Terraform fails to initialize

**Error:** `Error configuring the backend "cloud"`

**Solutions:**

1. Authenticate with Terraform Cloud:
   ```bash
   terraform login
   ```

2. Verify your organization and workspace names in `terraform/providers.tf`

3. Set the token as an environment variable:
   ```bash
   export TF_TOKEN_app_terraform_io="your-token"
   ```

### Terraform apply fails with "unauthorized"

**Error:** `Error: GET https://api.digitalocean.com/v2/account: 401 Unable to authenticate you`

**Solutions:**

1. Verify your DigitalOcean API token is correct
2. Check that `do_token` in `terraform.tfvars` is set
3. Ensure the token has write permissions

### Droplet creation times out

**Error:** `timeout while waiting for state to become 'active'`

**Solutions:**

1. Check DigitalOcean status: https://status.digitalocean.com/
2. Try a different region
3. Increase the timeout in `terraform/droplet.tf`
4. Verify you haven't hit account limits

## SSH and Connection Problems

### Cannot SSH to droplet

**Error:** `Connection refused` or `Permission denied`

**Solutions:**

1. **Check if droplet is running:**
   ```bash
   cd terraform
   terraform output droplet_ip
   ```

2. **Verify firewall rules:**
   - Check `allowed_ssh_ips` in `terraform.tfvars`
   - If empty, it allows from anywhere
   - If set, ensure your current IP is included

   ```bash
   # Get your current IP
   curl ifconfig.me
   ```

3. **Verify SSH key:**
   ```bash
   # Check if key is loaded
   ssh-add -l
   
   # Add your key
   ssh-add ~/.ssh/id_ed25519
   
   # Test with verbose output
   ssh -v root@<droplet-ip>
   ```

4. **Try using the key explicitly:**
   ```bash
   ssh -i ~/.ssh/id_ed25519 root@<droplet-ip>
   ```

### "Host key verification failed"

**Solutions:**

1. Remove old host key:
   ```bash
   ssh-keygen -R <droplet-ip>
   ```

2. Connect again (will prompt to add new key)

### Deployer user cannot SSH

**Solutions:**

1. **Verify deployer key is configured:**
   ```bash
   ssh root@<droplet-ip>
   cat /home/deployer/.ssh/authorized_keys
   ```

2. **Check deployer user exists:**
   ```bash
   id deployer
   ```

3. **Manually add SSH key:**
   ```bash
   ssh root@<droplet-ip>
   mkdir -p /home/deployer/.ssh
   echo "your-public-key-here" >> /home/deployer/.ssh/authorized_keys
   chown -R deployer:deployer /home/deployer/.ssh
   chmod 700 /home/deployer/.ssh
   chmod 600 /home/deployer/.ssh/authorized_keys
   ```

## Deployment Failures

### GitHub Actions deployment fails with "Permission denied"

**Solutions:**

1. **Verify secrets are set correctly:**
   - Repository Settings → Secrets → Actions
   - Check `SWARM_HOST`, `SWARM_SSH_KEY`, `SWARM_USER`

2. **Verify SSH key format:**
   - Key should include BEGIN and END markers
   - Should be the PRIVATE key (not .pub)
   - No extra whitespace or newlines

3. **Test SSH connection manually:**
   ```bash
   # Save secret to file
   echo "$SWARM_SSH_KEY" > /tmp/test_key
   chmod 600 /tmp/test_key
   
   # Test connection
   ssh -i /tmp/test_key deployer@$SWARM_HOST
   ```

### "docker stack deploy" fails

**Error:** `unable to resolve image 'ghcr.io/owner/repo:tag'`

**Solutions:**

1. **Verify image was built and pushed:**
   - Check GitHub Actions build logs
   - Verify package exists: https://github.com/owner/repo/pkgs/container/repo

2. **Check registry authentication:**
   ```bash
   ssh deployer@<droplet-ip>
   docker login ghcr.io -u your-username
   ```

3. **Manual pull test:**
   ```bash
   docker pull ghcr.io/owner/repo:tag
   ```

4. **Verify compose file references correct image:**
   ```yaml
   services:
     app:
       image: ghcr.io/owner/repo:latest  # Check this matches
   ```

### Stack deploys but services don't start

**Solutions:**

1. **Check service status:**
   ```bash
   ssh deployer@<droplet-ip>
   docker stack services <stack-name>
   docker service ps <stack-name>_<service-name> --no-trunc
   ```

2. **View service logs:**
   ```bash
   docker service logs <stack-name>_<service-name>
   ```

3. **Common issues:**
   - Port already in use by another service
   - Insufficient resources (memory/CPU)
   - Image doesn't exist or can't be pulled
   - Container crashes on startup

4. **Check for errors:**
   ```bash
   # Show failed tasks
   docker service ps <stack-name>_<service-name> --filter "desired-state=shutdown"
   ```

### "No such file or directory" when copying compose file

**Solutions:**

1. **Verify compose file exists:**
   ```bash
   ls -la docker-compose.yml
   ```

2. **Check working directory:**
   ```yaml
   # In workflow
   with:
     working_directory: ./path/to/directory
     compose_file: docker-compose.yml
   ```

3. **Verify file path in workflow:**
   - Path is relative to working_directory
   - Must exist in the repository

## Service Issues

### Service keeps restarting

**Solutions:**

1. **Check logs for errors:**
   ```bash
   docker service logs <stack-name>_<service-name> --tail 100
   ```

2. **Check resource limits:**
   ```bash
   docker service inspect <stack-name>_<service-name>
   ```

3. **Common causes:**
   - Application crashes immediately
   - Health check fails
   - Out of memory
   - Missing environment variables

4. **Temporarily disable health checks:**
   ```yaml
   services:
     app:
       healthcheck:
         disable: true
   ```

### Service shows 0/N replicas

**Solutions:**

1. **Check why tasks aren't starting:**
   ```bash
   docker service ps <stack-name>_<service-name> --no-trunc
   ```

2. **Look for scheduling constraints:**
   ```yaml
   deploy:
     placement:
       constraints:
         - node.role == manager  # Might be too restrictive
   ```

3. **Check node availability:**
   ```bash
   docker node ls
   ```

### Cannot access service via browser

**Solutions:**

1. **Verify service is running:**
   ```bash
   docker service ps <stack-name>_<service-name>
   ```

2. **Check port mapping:**
   ```yaml
   services:
     app:
       ports:
         - "80:8080"  # External:Internal
   ```

3. **Verify firewall allows traffic:**
   - HTTP (80) and HTTPS (443) should be open
   - Check DigitalOcean firewall rules

4. **Test from the droplet:**
   ```bash
   ssh deployer@<droplet-ip>
   curl http://localhost:80
   ```

5. **Check if port is listening:**
   ```bash
   sudo netstat -tlnp | grep :80
   ```

## Networking Problems

### Services can't communicate with each other

**Solutions:**

1. **Ensure services are on the same network:**
   ```yaml
   services:
     api:
       networks:
         - app-network
     
     worker:
       networks:
         - app-network
   
   networks:
     app-network:
       driver: overlay
   ```

2. **Use service names for DNS:**
   ```yaml
   environment:
     - API_URL=http://api:8080  # Use service name, not localhost
   ```

3. **Check network exists:**
   ```bash
   docker network ls
   ```

### Overlay network issues

**Solutions:**

1. **Recreate the network:**
   ```bash
   docker network rm <network-name>
   docker network create --driver overlay --attachable <network-name>
   ```

2. **Check swarm encryption settings:**
   ```bash
   docker network inspect <network-name>
   ```

## Performance Issues

### Services are slow or unresponsive

**Solutions:**

1. **Check resource usage:**
   ```bash
   docker stats
   ```

2. **Check droplet resources:**
   ```bash
   top
   free -h
   df -h
   ```

3. **Scale up resources:**
   
   Option A: Vertical scaling (bigger droplet)
   ```bash
   cd terraform
   # Edit terraform.tfvars: droplet_size = "s-2vcpu-4gb"
   terraform apply
   ```

   Option B: Horizontal scaling (more replicas)
   ```yaml
   services:
     app:
       deploy:
         replicas: 4  # Increase replicas
   ```

4. **Add resource limits:**
   ```yaml
   services:
     app:
       deploy:
         resources:
           limits:
             cpus: '1.0'
             memory: 1G
           reservations:
             cpus: '0.5'
             memory: 512M
   ```

### Out of disk space

**Solutions:**

1. **Check disk usage:**
   ```bash
   df -h
   docker system df
   ```

2. **Clean up Docker:**
   ```bash
   # Remove unused images
   docker image prune -a
   
   # Remove unused volumes
   docker volume prune
   
   # Remove stopped containers
   docker container prune
   
   # Remove everything unused
   docker system prune -a --volumes
   ```

3. **Enable automatic cleanup:**
   ```bash
   # Add to cron
   echo "0 2 * * * docker system prune -f" | crontab -
   ```

## Monitoring and Logs

### Viewing Logs

**Service logs:**
```bash
# All logs
docker service logs <stack-name>_<service-name>

# Follow logs
docker service logs -f <stack-name>_<service-name>

# Last 100 lines
docker service logs --tail 100 <stack-name>_<service-name>

# Logs since timestamp
docker service logs --since 30m <stack-name>_<service-name>
```

**Container logs:**
```bash
# Find container
docker ps | grep <service-name>

# View logs
docker logs <container-id>
```

**System logs:**
```bash
# Docker daemon logs
journalctl -u docker -f

# Cloud-init logs
journalctl -u cloud-init

# System logs
tail -f /var/log/syslog
```

### Grafana Alloy not collecting logs

**Solutions:**

1. **Check Alloy service status:**
   ```bash
   docker service ps monitoring_alloy
   docker service logs monitoring_alloy
   ```

2. **Verify Alloy configuration:**
   ```bash
   cat /tmp/alloy-config.alloy
   ```

3. **Check Grafana Cloud credentials:**
   - Verify endpoint URL
   - Check username and API key
   - Test with curl:
   ```bash
   curl -u "username:api_key" https://your-instance.grafana.net/api/prom/push
   ```

4. **Restart Alloy:**
   ```bash
   docker service update --force monitoring_alloy
   ```

### Cannot access Alloy UI

**URL:** `http://<droplet-ip>:12345`

**Solutions:**

1. **Check if port 12345 is open:**
   ```bash
   sudo netstat -tlnp | grep 12345
   ```

2. **Add firewall rule if needed:**
   
   Edit `terraform/firewall.tf`:
   ```hcl
   inbound_rule {
     protocol         = "tcp"
     port_range       = "12345"
     source_addresses = ["YOUR_IP/32"]
   }
   ```
   
   Apply changes:
   ```bash
   terraform apply
   ```

3. **Check Alloy is running:**
   ```bash
   docker service ps monitoring_alloy
   ```

## Docker Swarm Issues

### "This node is not a swarm manager"

**Solutions:**

1. **Check swarm status:**
   ```bash
   docker info | grep Swarm
   ```

2. **Reinitialize swarm:**
   ```bash
   sudo /usr/local/bin/init-swarm.sh
   ```

3. **Force init (destructive):**
   ```bash
   docker swarm leave --force
   docker swarm init --advertise-addr $(curl -s http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)
   ```

### Cannot leave swarm

**Error:** `node is part of an active swarm`

**Solutions:**

1. **Remove all stacks first:**
   ```bash
   docker stack ls
   docker stack rm <stack-name>
   ```

2. **Wait for services to stop:**
   ```bash
   docker service ls
   ```

3. **Then leave:**
   ```bash
   docker swarm leave --force
   ```

## Getting Help

If you're still stuck:

1. **Check Docker Swarm docs:** https://docs.docker.com/engine/swarm/
2. **Check DigitalOcean docs:** https://docs.digitalocean.com/
3. **Review GitHub Actions logs:** Check the Actions tab in your repository
4. **Enable debug logging:**
   ```yaml
   # In your GitHub Actions workflow
   jobs:
     deploy:
       steps:
         - name: Enable debug
           run: echo "ACTIONS_STEP_DEBUG=true" >> $GITHUB_ENV
   ```

5. **SSH to the droplet and investigate:**
   ```bash
   ssh deployer@<droplet-ip>
   docker service ls
   docker service logs <service-name>
   journalctl -u docker -f
   ```

## Common Error Messages

### "no space left on device"

See [Out of disk space](#out-of-disk-space)

### "connection refused"

See [Cannot access service via browser](#cannot-access-service-via-browser)

### "name conflicts with an existing object"

A resource with that name already exists:

```bash
# Remove old stack
docker stack rm <stack-name>

# Remove old network
docker network rm <network-name>

# Remove old volume
docker volume rm <volume-name>
```

### "node is down"

Node has lost connection to the swarm:

```bash
# Check node status
docker node ls

# If node shows as down, try to reconnect
docker node update --availability active <node-id>
```

## Preventive Measures

1. **Monitor disk space:**
   ```bash
   echo "0 */6 * * * docker system prune -f" | crontab -
   ```

2. **Set up log rotation:**
   Docker is already configured with log rotation in `/etc/docker/daemon.json`

3. **Monitor resource usage:**
   - Use Grafana Alloy to send metrics to Grafana Cloud
   - Set up alerts for high CPU/memory usage

4. **Regular backups:**
   ```bash
   # Backup volumes
   docker run --rm -v <volume-name>:/data -v $(pwd):/backup alpine tar czf /backup/volume-backup.tar.gz /data
   ```

5. **Test deployments:**
   - Deploy to staging first
   - Use health checks
   - Monitor logs after deployment
