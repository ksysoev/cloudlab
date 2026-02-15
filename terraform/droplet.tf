# Main Swarm manager droplet
resource "digitalocean_droplet" "swarm_manager" {
  name   = var.droplet_name
  region = var.do_region
  size   = var.droplet_size
  image  = "ubuntu-24-04-x64"

  ssh_keys = [digitalocean_ssh_key.cloudlab.id]

  # User data for bootstrap only (Ansible handles the rest)
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    deployer_ssh_key = var.ssh_public_key
    ssh_port         = var.ssh_port
  })

  tags = var.tags

  # Enable monitoring
  monitoring = true

  # Enable IPv6
  ipv6 = true

  # Ensure the droplet is recreated if user_data changes
  lifecycle {
    create_before_destroy = true
  }
}

