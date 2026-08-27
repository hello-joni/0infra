terraform {

  # Manually created Hetzner S3-compatible bucket for OpenTofu backend
  backend "s3" {
    bucket = "joni-opentofu"
    key    = "opentofu/terraform.tfstate"
    region = "us-east-1"

    endpoints = {
      s3 = "https://hel1.your-objectstorage.com"
    }

    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
  }

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.66"
    }
    dnsimple = {
      source  = "dnsimple/dnsimple"
      version = "~> 1.9"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.29"
    }
  }
}

provider "hcloud" {}

provider "tailscale" {}

module "infra" {
  source = "./infra"

  pii_email      = var.pii_email
  pii_address    = var.pii_address
  pii_city       = var.pii_city
  pii_state      = var.pii_state
  pii_postal_code = var.pii_postal_code
  pii_country    = var.pii_country
  pii_first_name = var.pii_first_name
  pii_last_name  = var.pii_last_name
  pii_middle_name = var.pii_middle_name
  pii_phone      = var.pii_phone
}

output "server_ip_addresses" {
  value = module.infra.server_ip_addresses
}
