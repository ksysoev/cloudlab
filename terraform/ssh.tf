# SSH key for root access to the droplet
resource "digitalocean_ssh_key" "cloudlab" {
  name       = "cloudlab-terraform-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}
