output "droplet_id" {
  description = "ID of the created droplet"
  value       = digitalocean_droplet.swarm_manager.id
}

output "droplet_ip" {
  description = "Public IP address of the droplet"
  value       = digitalocean_droplet.swarm_manager.ipv4_address
}

output "droplet_name" {
  description = "Name of the droplet"
  value       = digitalocean_droplet.swarm_manager.name
}

output "droplet_region" {
  description = "Region where the droplet is deployed"
  value       = digitalocean_droplet.swarm_manager.region
}

output "ssh_connection_string" {
  description = "SSH connection string for the droplet (deployer user)"
  value       = "ssh -p ${var.ssh_port} deployer@${digitalocean_droplet.swarm_manager.ipv4_address}"
}

output "root_connection_string" {
  description = "SSH connection string for root user (disabled for security - use deployer instead)"
  value       = "ssh -p ${var.ssh_port} root@${digitalocean_droplet.swarm_manager.ipv4_address} (ROOT LOGIN DISABLED)"
}

output "ssh_port" {
  description = "SSH port configured on the droplet"
  value       = var.ssh_port
}

output "swarm_manager_ip" {
  description = "IP address of the Swarm manager node"
  value       = digitalocean_droplet.swarm_manager.ipv4_address
  sensitive   = false
}
