terraform {
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
  }
}

provider "hcloud" {}
