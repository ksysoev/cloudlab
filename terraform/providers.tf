terraform {
  required_version = ">= 1.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  # Terraform Cloud backend configuration
  # Organization is set via TFC_CLOUD_ORGANIZATION environment variable
  cloud {
    workspaces {
      name = "cloudlab-infrastructure"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}
