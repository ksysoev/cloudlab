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
  description = "SSH connection string for the droplet"
  value       = "ssh root@${digitalocean_droplet.swarm_manager.ipv4_address}"
}

output "deployer_connection_string" {
  description = "SSH connection string for the deployer user"
  value       = "ssh deployer@${digitalocean_droplet.swarm_manager.ipv4_address}"
}

output "swarm_manager_ip" {
  description = "IP address of the Swarm manager node"
  value       = digitalocean_droplet.swarm_manager.ipv4_address
  sensitive   = false
}
