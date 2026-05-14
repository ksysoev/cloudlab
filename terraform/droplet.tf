# Main Swarm manager droplet
resource "digitalocean_droplet" "swarm_manager" {
  name   = var.droplet_name
  region = var.do_region
  size   = var.droplet_size
  image  = "ubuntu-24-04-x64"

  ssh_keys = [digitalocean_ssh_key.cloudlab.id]

  tags = var.tags

  # Enable monitoring
  monitoring = true

  # Enable weekly backups (DigitalOcean managed, adds 20% to droplet cost)
  backups = var.backups_enabled

  # Enable IPv6
  ipv6 = true

  lifecycle {
    create_before_destroy = true
    # Ignore user_data changes to prevent accidental droplet recreation
    ignore_changes = [user_data]
  }
}

