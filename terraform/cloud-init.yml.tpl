#cloud-config
# cloud-init user_data — rendered by Terraform and injected into every
# droplet deployed from the Packer-built cloudlab snapshot.
#
# Handles the three things that cannot be baked into the image:
#   1. deployer SSH public key  (varies per environment/operator)
#   2. Docker Swarm init        (requires the real public IP at boot)
#   3. Grafana Alloy config     (contains secrets — URLs, IDs, API key)

# ── SSH key injection ─────────────────────────────────────────────────────────
# Adds the deployer public key without touching root.  The image already has
# the deployer user and sudo rule; this just populates authorized_keys.
users:
  - name: deployer
    ssh_authorized_keys:
      - ${deployer_ssh_public_key}

# ── Runtime config files ──────────────────────────────────────────────────────
write_files:
  # Grafana Alloy config with real credentials — overwrites the placeholder
  # written by the 04-monitoring.sh Packer script.
  - path: /etc/alloy/config.alloy
    owner: root:root
    permissions: "0600"
    content: |
      ${indent(6, alloy_config)}

  # Alloy environment (already set in image but written again for clarity)
  - path: /etc/default/alloy
    owner: root:root
    permissions: "0644"
    content: |
      CONFIG_FILE="/etc/alloy/config.alloy"

# ── First-boot commands ───────────────────────────────────────────────────────
# runcmd runs as root after write_files, in the order listed.
runcmd:
  # Ensure Docker is fully started before Swarm init
  - systemctl start docker
  - systemctl is-active --quiet docker || (echo "Docker failed to start" && exit 1)

  # Initialise Docker Swarm using this droplet's own public IPv4.
  # The DigitalOcean metadata endpoint is always reachable from within a droplet.
  - |
    PUBLIC_IP=$(curl -sf --retry 5 --retry-delay 2 \
      http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)
    if [ -z "$PUBLIC_IP" ]; then
      echo "ERROR: Could not determine public IP from metadata endpoint."
      exit 1
    fi
    if [ "$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || echo inactive)" = "active" ]; then
      echo "Swarm already initialised, skipping."
    else
      echo "Initialising Docker Swarm with advertise-addr $PUBLIC_IP"
      docker swarm init --advertise-addr "$PUBLIC_IP"
    fi

  # Create the shared overlay network used by all application stacks
  - |
    docker network create \
      --driver overlay \
      --attachable \
      "${swarm_overlay_network}" \
    || echo "Overlay network already exists, skipping."

  # Write Alloy config and start the service now that credentials are present
  - systemctl start alloy
  - systemctl is-active --quiet alloy || echo "WARNING: Alloy failed to start, check /etc/alloy/config.alloy"

final_message: |
  CloudLab droplet is ready.
  Deployer SSH key injected, Docker Swarm initialised, Grafana Alloy running.
  Boot completed in $UPTIME seconds.
