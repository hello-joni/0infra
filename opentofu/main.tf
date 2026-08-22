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
  }
}

provider "hcloud" {}

resource "hcloud_primary_ip" "wasabi_ipv4" {
  auto_delete       = false
  delete_protection = false
  labels            = {}
  location          = "hil"
  name              = "primary_ip-wasabi-ipv4"
  type              = "ipv4"

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_primary_ip" "wasabi_ipv6" {
  auto_delete       = false
  delete_protection = false
  labels            = {}
  location          = "hil"
  name              = "primary_ip-128299545"
  type              = "ipv6"

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_primary_ip" "sh_sassafras_ipv4" {
  auto_delete       = false
  delete_protection = false
  labels            = {}
  location          = "hil"
  name              = "primary_ip-sh-sassafras-ipv4"
  type              = "ipv4"

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_primary_ip" "sh_sassafras_ipv6" {
  auto_delete       = false
  delete_protection = false
  labels            = {}
  location          = "hil"
  name              = "primary_ip-128597215"
  type              = "ipv6"

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_server" "wasabi" {
  backups                    = false
  delete_protection          = false
  firewall_ids               = []
  ignore_remote_firewall_ids = null
  image                      = "rocky-10"
  iso                        = null
  keep_disk                  = null
  labels                     = {}
  location                   = "hil"
  name                       = "wasabi"
  placement_group_id         = 0
  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.wasabi_ipv4.id
    ipv6_enabled = true
    ipv6         = hcloud_primary_ip.wasabi_ipv6.id
  }
  rebuild_protection       = false
  rescue                   = null
  server_type              = "cpx11"
  shutdown_before_deletion = null
  ssh_keys                 = null
  user_data                = null

  # Ensure primary IPs (and their auto_delete settings) are fully applied
  # before any public_net reconciliation touches their assignments.
  depends_on = [
    hcloud_primary_ip.wasabi_ipv4,
    hcloud_primary_ip.wasabi_ipv6,
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_server" "sh_sassafras" {
  backups                    = true
  delete_protection          = false
  firewall_ids               = []
  ignore_remote_firewall_ids = null
  image                      = "rocky-10"
  iso                        = null
  keep_disk                  = null
  labels                     = {}
  location                   = "hil"
  name                       = "sh-sassafras"
  placement_group_id         = 0
  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.sh_sassafras_ipv4.id
    ipv6_enabled = true
    ipv6         = hcloud_primary_ip.sh_sassafras_ipv6.id
  }
  rebuild_protection       = false
  rescue                   = null
  server_type              = "cpx21"
  shutdown_before_deletion = null
  ssh_keys                 = null
  user_data                = null

  # Ensure primary IPs (and their auto_delete settings) are fully applied
  # before any public_net reconciliation touches their assignments.
  depends_on = [
    hcloud_primary_ip.sh_sassafras_ipv4,
    hcloud_primary_ip.sh_sassafras_ipv6,
  ]

  lifecycle {
    prevent_destroy = true
  }
}
