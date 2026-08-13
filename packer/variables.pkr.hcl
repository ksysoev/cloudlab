variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "do_region" {
  description = "DigitalOcean region for the build droplet"
  type        = string
  default     = "fra1"
}

variable "do_builder_size" {
  description = "Droplet size used during Packer build (discarded after snapshot)"
  type        = string
  default     = "s-1vcpu-1gb" # Cheapest size — only lives for the build duration
}

variable "ssh_port" {
  description = "Custom SSH port baked into the image"
  type        = number
  default     = 1923
}

variable "snapshot_regions" {
  description = "Additional regions to copy the snapshot to (builder region is always included)"
  type        = list(string)
  default     = []
}
