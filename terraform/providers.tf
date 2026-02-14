terraform {
  required_version = ">= 1.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }

  # Terraform Cloud backend configuration
  # Run `terraform login` to authenticate
  cloud {
    organization = "REPLACE_WITH_YOUR_ORG"

    workspaces {
      name = "cloudlab-infrastructure"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}
