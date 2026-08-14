# -----------------------------------------------------------------------------
# Packer image
# -----------------------------------------------------------------------------

variable "cloudlab_image_id" {
  description = "DigitalOcean snapshot ID (or slug) produced by the Packer build workflow. Changing this value triggers a droplet replacement."
  type        = string
}

# -----------------------------------------------------------------------------
# DigitalOcean credentials & placement
# -----------------------------------------------------------------------------

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "do_region" {
  description = "DigitalOcean region for the droplet"
  type        = string
  default     = "sgp1"
}

variable "ssh_port" {
  description = "SSH port (non-standard for security)"
  type        = number
  default     = 1923
}

variable "droplet_size" {
  description = "Size of the droplet"
  type        = string
  default     = "s-1vcpu-1gb" # Regular - $6/mo, 1GB RAM, 1 vCPU
}

variable "droplet_name" {
  description = "Name of the droplet"
  type        = string
  default     = "cloudlab-swarm"
}

variable "ssh_public_key" {
  description = "SSH public key registered with DigitalOcean (for emergency root access via DO console/recovery). Not used for normal deployer SSH login."
  type        = string
}

variable "deployer_ssh_public_key" {
  description = "SSH public key injected into /home/deployer/.ssh/authorized_keys by cloud-init. Must match the private key in the SWARM_SSH_KEY / SSH_PRIVATE_KEY GitHub secret used by CI/CD workflows."
  type        = string
}

variable "allowed_ssh_ips" {
  description = "List of IP addresses allowed to SSH (empty = allow all). Note: IP whitelisting removed as no static IP available."
  type        = list(string)
  default     = []
}

variable "grafana_cloud_logs_url" {
  description = "Grafana Cloud Loki push endpoint URL (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "grafana_cloud_logs_id" {
  description = "Grafana Cloud Loki instance ID (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "grafana_cloud_metrics_url" {
  description = "Grafana Cloud Prometheus push endpoint URL (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "grafana_cloud_metrics_id" {
  description = "Grafana Cloud Prometheus instance ID (optional)"
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

variable "swarm_overlay_network" {
  description = "Name of the Docker overlay network created at first boot by cloud-init"
  type        = string
  default     = "cloudlab-public"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,62}$", var.swarm_overlay_network))
    error_message = "swarm_overlay_network must start with an alphanumeric character and contain only letters, digits, dot (.), underscore (_), or hyphen (-), up to 63 characters."
  }
}

variable "backups_enabled" {
  description = "Enable weekly backups for the droplet (adds 20% to droplet cost)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = ["cloudlab", "swarm", "terraform"]
}

# Cloudflare configuration
variable "cloudflare_api_token" {
  description = "Cloudflare API token for DNS management"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_name" {
  description = "Cloudflare zone name (domain)"
  type        = string
  default     = "make-it-public.dev"
}

