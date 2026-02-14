terraform {
  required_version = ">= 1.0"

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  # Terraform Cloud backend configuration
  # Run `terraform login` to authenticate
  # TODO: Replace "YOUR_ORG_NAME" with your actual Terraform Cloud organization name
  cloud {
    organization = "YOUR_ORG_NAME"

    workspaces {
      name = "cloudlab-infrastructure"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}
