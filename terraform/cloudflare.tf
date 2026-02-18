# Cloudflare DNS configuration
# This file manages DNS records for the domain hosted on Cloudflare

# Fetch the Cloudflare zone for the domain
data "cloudflare_zone" "main" {
  name = var.cloudflare_zone_name
}

# A record for root domain (make-it-public.dev)
# Not proxied - allows direct connection for SSH on custom port
resource "cloudflare_record" "root" {
  zone_id = data.cloudflare_zone.main.id
  name    = "@"
  content = digitalocean_droplet.swarm_manager.ipv4_address
  type    = "A"
  ttl     = 1 # Auto TTL (managed by Cloudflare, ~300 seconds)
  proxied = false

  comment = "Managed by Terraform - Points to DigitalOcean droplet"
}

# A record for wildcard subdomain (*.make-it-public.dev)
# Proxied through Cloudflare - provides DDoS protection and CDN
resource "cloudflare_record" "wildcard" {
  zone_id = data.cloudflare_zone.main.id
  name    = "*"
  content = digitalocean_droplet.swarm_manager.ipv4_address
  type    = "A"
  ttl     = 1 # Auto TTL (when proxied, Cloudflare manages this)
  proxied = true

  comment = "Managed by Terraform - Wildcard subdomain with Cloudflare protection"
}
