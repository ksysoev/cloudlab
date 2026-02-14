# Data source to get the latest Ubuntu 24.04 LTS image
data "digitalocean_images" "ubuntu" {
  filter {
    key    = "distribution"
    values = ["Ubuntu"]
  }
  filter {
    key    = "name"
    values = ["24.04"]
  }
  sort {
    key       = "created"
    direction = "desc"
  }
}

# Main Swarm manager droplet
resource "digitalocean_droplet" "swarm_manager" {
  name   = var.droplet_name
  region = var.do_region
  size   = var.droplet_size
  image  = data.digitalocean_images.ubuntu.images[0].slug

  ssh_keys = [digitalocean_ssh_key.cloudlab.id]

  # User data for initial setup
  user_data = templatefile("${path.module}/cloud-init.yaml", {
    deployer_ssh_key       = var.deployer_ssh_public_key != "" ? var.deployer_ssh_public_key : file(pathexpand(var.ssh_public_key_path))
    ssh_port               = var.ssh_port
    grafana_cloud_endpoint = var.grafana_cloud_endpoint
    grafana_cloud_username = var.grafana_cloud_username
    grafana_cloud_api_key  = var.grafana_cloud_api_key
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

# Wait for the droplet to be fully initialized
resource "null_resource" "wait_for_cloud_init" {
  depends_on = [digitalocean_droplet.swarm_manager]

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait",
      "echo 'Cloud-init completed, verifying Docker installation...'",
      "docker info",
    ]

    connection {
      type        = "ssh"
      user        = "root"
      host        = digitalocean_droplet.swarm_manager.ipv4_address
      port        = var.ssh_port
      private_key = file(pathexpand(var.ssh_private_key_path))
      timeout     = "10m"
      # Add retry logic for SSH port change during cloud-init
      agent = false
    }
  }
}
