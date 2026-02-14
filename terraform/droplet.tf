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
    deployer_ssh_key          = var.deployer_ssh_public_key != "" ? var.deployer_ssh_public_key : var.ssh_public_key
    ssh_port                  = var.ssh_port
    grafana_cloud_logs_url    = var.grafana_cloud_logs_url
    grafana_cloud_logs_id     = var.grafana_cloud_logs_id
    grafana_cloud_metrics_url = var.grafana_cloud_metrics_url
    grafana_cloud_metrics_id  = var.grafana_cloud_metrics_id
    grafana_cloud_api_key     = var.grafana_cloud_api_key
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

