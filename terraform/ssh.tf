# SSH key for root access to the droplet
resource "digitalocean_ssh_key" "cloudlab" {
  name       = "cloudlab-terraform-key"
  public_key = var.ssh_public_key
}
