packer {
  required_version = ">= 1.11.0"

  required_plugins {
    digitalocean = {
      version = ">= 1.4.0"
      source  = "github.com/digitalocean/digitalocean"
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Source: DigitalOcean ephemeral build droplet
# ─────────────────────────────────────────────────────────────────────────────
source "digitalocean" "cloudlab" {
  api_token = var.do_token

  # Base image — same OS that Terraform used to provision bare droplets
  image  = "ubuntu-24-04-x64"
  region = var.do_region
  size   = var.do_builder_size

  # Packer SSHes in as root for provisioning (standard for DO builds)
  ssh_username = "root"

  # Snapshot naming — timestamp makes every build uniquely addressable
  snapshot_name    = "cloudlab-${formatdate("YYYYMMDD-HHmmss", timestamp())}"
  snapshot_regions = var.snapshot_regions

  tags = ["packer", "cloudlab"]
}

# ─────────────────────────────────────────────────────────────────────────────
# Build: provision, harden, and snapshot
# ─────────────────────────────────────────────────────────────────────────────
build {
  name    = "cloudlab"
  sources = ["source.digitalocean.cloudlab"]

  # ── Shell provisioners (run in order) ─────────────────────────────────────

  # 1. Base system: packages, deployer user, directory layout, auto-upgrades
  provisioner "shell" {
    script          = "${path.root}/scripts/01-base.sh"
    execute_command = "bash -euo pipefail '{{ .Path }}'"
  }

  # 2. Docker CE + daemon config + compose plugin
  provisioner "shell" {
    script          = "${path.root}/scripts/02-docker.sh"
    execute_command = "bash -euo pipefail '{{ .Path }}'"
  }

  # 3. UFW firewall, fail2ban, SSH hardening
  provisioner "shell" {
    # Pass the SSH port as an env var so the script stays param-driven
    environment_vars = ["SSH_PORT=${var.ssh_port}"]
    script           = "${path.root}/scripts/03-security.sh"
    execute_command  = "bash -euo pipefail '{{ .Path }}'"
  }

  # 4. Grafana Alloy: install binary, create system user, wire up data dir
  provisioner "shell" {
    script          = "${path.root}/scripts/04-monitoring.sh"
    execute_command = "bash -euo pipefail '{{ .Path }}'"
  }

  # ── Static config files ────────────────────────────────────────────────────

  # Docker daemon options (log rotation + metrics endpoint)
  provisioner "file" {
    source      = "${path.root}/files/daemon.json"
    destination = "/etc/docker/daemon.json"
  }

  # ── Post-file fixups ───────────────────────────────────────────────────────

  # Ensure correct ownership/permissions on uploaded files
  provisioner "shell" {
    inline = [
      "chown root:root /etc/docker/daemon.json /etc/fail2ban/jail.local /etc/ssh/sshd_config.d/00-custom-port.conf",
      "chmod 0644 /etc/docker/daemon.json /etc/fail2ban/jail.local /etc/ssh/sshd_config.d/00-custom-port.conf",
      "mkdir -p /run/sshd",
      "chmod 0755 /run/sshd",
      "sshd -t",
    ]
  }

  # ── Cleanup: reset machine-specific state before snapshotting ─────────────

  provisioner "shell" {
    script          = "${path.root}/scripts/99-cleanup.sh"
    execute_command = "bash -euo pipefail '{{ .Path }}'"
  }
}
