#cloud-config
# cloud-init user_data - rendered by Terraform and injected into every
# droplet deployed from the Packer-built cloudlab snapshot.
#
# Handles the three things that cannot be baked into the image:
#   1. deployer SSH public key  (varies per environment/operator)
#   2. Docker Swarm init        (requires the real public IP at boot)
#   3. Grafana Alloy config     (contains secrets - URLs, IDs, API key)

# -- Runtime config files (incl. SSH key injection) ---------------------------
# authorized_keys is written via write_files - more reliable than the users:
# stanza when the deployer user is pre-created by the Packer image.
# cloud-init's users: block silently skips ssh_authorized_keys for existing
# users on Ubuntu 24.04, so we own the file directly here instead.
#
# NOTE: cloud-init allows only one write_files: key per document. SSH key
# injection and runtime config files are therefore merged into this single block.
write_files:
  # -- SSH key for deployer user ---------------------------------------------
  - path: /home/deployer/.ssh/authorized_keys
    owner: deployer:deployer
    permissions: "0600"
    content: |
      ${deployer_ssh_public_key}

  # -- Grafana Alloy config --------------------------------------------------
  # Overwrites the placeholder written by the 04-monitoring.sh Packer script.
  - path: /etc/alloy/config.alloy
    owner: root:alloy
    permissions: "0640"
    content: |
      ${indent(6, alloy_config)}

  # Alloy environment (already set in image but written again for clarity)
  - path: /etc/default/alloy
    owner: root:root
    permissions: "0644"
    content: |
      CONFIG_FILE="/etc/alloy/config.alloy"

# -- First-boot commands -----------------------------------------------------
# runcmd runs as root after write_files, in the order listed.
runcmd:
  # Verify that write_files wrote the deployer SSH key successfully.
  # If the authorized_keys file is missing or empty the boot is aborted early
  # so the failure is visible in 'cloud-init status --long' rather than
  # silently producing a droplet the deployer cannot log in to.
  - |
    if [ ! -s /home/deployer/.ssh/authorized_keys ]; then
      echo "ERROR: /home/deployer/.ssh/authorized_keys is missing or empty."
      echo "write_files may have failed - check cloud-init logs for YAML parse errors."
      exit 1
    fi

  # Ensure Docker is fully started before Swarm init
  - systemctl start docker
  - systemctl is-active --quiet docker || (echo "Docker failed to start" && exit 1)

  # Wait for the Docker socket to be ready to accept connections (up to 30s).
  # systemctl is-active returns 'active' before the socket is ready.
  - |
    set -euo pipefail
    for i in $(seq 1 30); do
      if docker info > /dev/null 2>&1; then
        echo "Docker socket ready after ${i}s"
        break
      fi
      if [ "$i" -eq 30 ]; then
        echo "ERROR: Docker socket not ready after 30 seconds."
        exit 1
      fi
      sleep 1
    done

  # Initialise Docker Swarm using this droplet's own public IPv4.
  # The DigitalOcean metadata endpoint is always reachable from within a droplet.
  - |
    set -euo pipefail
    PUBLIC_IP=$(curl -sf --retry 5 --retry-delay 2 \
      http://169.254.169.254/metadata/v1/interfaces/public/0/ipv4/address)
    if [ -z "$PUBLIC_IP" ]; then
      echo "ERROR: Could not determine public IP from metadata endpoint."
      exit 1
    fi
    SWARM_STATE=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || echo inactive)
    if [ "$SWARM_STATE" = "active" ]; then
      echo "Swarm already initialised, skipping."
    else
      echo "Initialising Docker Swarm with advertise-addr $PUBLIC_IP"
      docker swarm init --advertise-addr "$PUBLIC_IP"
      echo "Docker Swarm initialised successfully."
    fi

  # Create the shared overlay network used by all application stacks
  - |
    set -euo pipefail
    if docker network ls --format '{{.Name}}' | grep -qx "${swarm_overlay_network}"; then
      echo "Overlay network '${swarm_overlay_network}' already exists, skipping."
    else
      docker network create \
        --driver overlay \
        --attachable \
        "${swarm_overlay_network}"
      echo "Overlay network '${swarm_overlay_network}' created."
    fi

  # Write Alloy config and start the service now that credentials are present
  - systemctl start alloy
  - |
    systemctl is-active --quiet alloy || echo "WARNING: Alloy failed to start, check /etc/alloy/config.alloy"

  # Remove cloud-init's sshd drop-in if cc_ssh recreated it during this boot.
  # Port directives are cumulative in sshd_config - leaving 50-cloud-init.conf
  # in place risks sshd listening on port 22 in addition to our custom port.
  # 00-custom-port.conf (baked by Packer) is the sole authoritative sshd config.
  - rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf
  - systemctl restart ssh

final_message: |
  CloudLab droplet is ready.
  Deployer SSH key injected, Docker Swarm initialised, Grafana Alloy running.
  Boot completed in $UPTIME seconds.
