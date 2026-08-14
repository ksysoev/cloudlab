# -----------------------------------------------------------------------------
# Grafana Alloy config - rendered with secrets, embedded in cloud-init
# -----------------------------------------------------------------------------
locals {
  alloy_config = templatefile("${path.module}/alloy-config.alloy.tpl", {
    swarm_instance_name       = var.droplet_name
    grafana_cloud_metrics_url = var.grafana_cloud_metrics_url
    grafana_cloud_metrics_id  = var.grafana_cloud_metrics_id
    grafana_cloud_logs_url    = var.grafana_cloud_logs_url
    grafana_cloud_logs_id     = var.grafana_cloud_logs_id
    grafana_cloud_api_key     = var.grafana_cloud_api_key
  })

  cloud_init_rendered = templatefile("${path.module}/cloud-init.yml.tpl", {
    deployer_ssh_public_key = var.deployer_ssh_public_key
    alloy_config            = local.alloy_config
    swarm_overlay_network   = var.swarm_overlay_network
  })
}

# -----------------------------------------------------------------------------
# Main Swarm manager droplet - deployed from a Packer-built snapshot
# -----------------------------------------------------------------------------
resource "digitalocean_droplet" "swarm_manager" {
  name   = var.droplet_name
  region = var.do_region
  size   = var.droplet_size

  # Packer-built snapshot ID - contains pre-installed Docker, Alloy, UFW,
  # fail2ban, deployer user, and SSH hardening.
  # Changing this value triggers a droplet replacement (create_before_destroy).
  image = var.cloudlab_image_id

  # Root SSH key - used only for emergency access; normal access is via
  # the deployer user whose key is injected by cloud-init (user_data below).
  ssh_keys = [digitalocean_ssh_key.cloudlab.id]

  tags = var.tags

  # Enable DigitalOcean's built-in host-level metrics agent
  monitoring = true

  # Weekly managed backups (adds ~20% to droplet cost)
  backups = var.backups_enabled

  # Enable IPv6
  ipv6 = true

  # cloud-init payload - injects SSH key, initialises Swarm, writes Alloy config
  user_data = sensitive(local.cloud_init_rendered)

  lifecycle {
    # New droplet is created and DNS updated before the old one is destroyed,
    # giving near-zero-downtime replacements when the image or user_data changes.
    create_before_destroy = true

    # NOTE: ignore_changes for user_data is intentionally removed.
    # With immutable images, a change to user_data (e.g. new secrets) or image
    # (new Packer snapshot) should produce a full replacement, not an in-place
    # mutation that Terraform ignores.
  }
}
