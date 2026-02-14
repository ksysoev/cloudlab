variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "do_region" {
  description = "DigitalOcean region for the droplet"
  type        = string
  default     = "fra1"
}

variable "ssh_port" {
  description = "SSH port (non-standard for security)"
  type        = number
  default     = 1923
}

variable "droplet_size" {
  description = "Size of the droplet"
  type        = string
  default     = "s-1vcpu-2gb" # Regular - $12/mo, 2GB RAM, 1 vCPU
}

variable "droplet_name" {
  description = "Name of the droplet"
  type        = string
  default     = "cloudlab-swarm"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key for droplet access"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for provisioning"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "deployer_ssh_public_key" {
  description = "SSH public key for the deployer user (used by GitHub Actions)"
  type        = string
  default     = ""
}

variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to SSH (empty = allow all). Note: IP whitelisting removed as no static IP available."
  type        = list(string)
  default     = []
}

variable "grafana_cloud_endpoint" {
  description = "Grafana Cloud endpoint for metrics and logs (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "grafana_cloud_username" {
  description = "Grafana Cloud username for authentication (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "grafana_cloud_api_key" {
  description = "Grafana Cloud API key for authentication (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = ["cloudlab", "swarm", "terraform"]
}
