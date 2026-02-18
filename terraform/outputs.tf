output "droplet_id" {
  description = "ID of the created droplet"
  value       = digitalocean_droplet.swarm_manager.id
  sensitive   = true
}

output "droplet_ip" {
  description = "Public IP address of the droplet"
  value       = digitalocean_droplet.swarm_manager.ipv4_address
  sensitive   = true
}

output "droplet_name" {
  description = "Name of the droplet"
  value       = digitalocean_droplet.swarm_manager.name
  sensitive   = true
}

output "droplet_region" {
  description = "Region where the droplet is deployed"
  value       = digitalocean_droplet.swarm_manager.region
  sensitive   = true
}

output "ssh_connection_string" {
  description = "SSH connection string for the droplet (deployer user)"
  value       = "ssh -p ${var.ssh_port} deployer@${digitalocean_droplet.swarm_manager.ipv4_address}"
  sensitive   = true
}

output "deployer_connection_string" {
  description = "SSH connection string for the deployer user"
  value       = "ssh -p ${var.ssh_port} deployer@${digitalocean_droplet.swarm_manager.ipv4_address}"
  sensitive   = true
}

output "root_connection_string" {
  description = "SSH connection string for root user (DEPRECATED: root login is disabled for security)"
  value       = "ssh -p ${var.ssh_port} root@${digitalocean_droplet.swarm_manager.ipv4_address}"
  sensitive   = true
}

output "ssh_port" {
  description = "SSH port configured on the droplet"
  value       = var.ssh_port
  sensitive   = true
}

output "swarm_manager_ip" {
  description = "IP address of the Swarm manager node"
  value       = digitalocean_droplet.swarm_manager.ipv4_address
  sensitive   = true
}

output "backups_enabled" {
  description = "Whether weekly backups are enabled for the droplet"
  value       = var.backups_enabled
}

# Cloudflare DNS outputs
output "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  value       = data.cloudflare_zone.main.id
}

output "dns_root_domain" {
  description = "Root domain DNS record (not proxied for SSH access)"
  value       = "${cloudflare_record.root.name == "@" ? var.cloudflare_zone_name : cloudflare_record.root.hostname} -> ${cloudflare_record.root.content} (proxied: ${cloudflare_record.root.proxied})"
}

output "dns_wildcard_domain" {
  description = "Wildcard domain DNS record (proxied through Cloudflare)"
  value       = "${cloudflare_record.wildcard.hostname} -> ${cloudflare_record.wildcard.content} (proxied: ${cloudflare_record.wildcard.proxied})"
}
