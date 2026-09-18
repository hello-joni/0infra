# Hetzner Cloud servers and primary IPs.

# ---------------------------------------------------------
# noios
#
# NixOS Caddy webserver which hosts joni.site

resource "hcloud_primary_ip" "noios_ipv4" {
  auto_delete       = false
  delete_protection = false
  labels            = {}
  location          = "hil"
  name              = "primary_ip-noios-ipv4"
  type              = "ipv4"

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_primary_ip" "noios_ipv6" {
  auto_delete       = false
  delete_protection = false
  labels            = {}
  location          = "hil"
  name              = "primary_ip-noios-ipv6"
  type              = "ipv6"

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_server" "noios" {
  backups                    = false
  delete_protection          = false
  firewall_ids               = []
  ignore_remote_firewall_ids = null
  image                      = "debian-13"
  iso                        = null
  keep_disk                  = null
  labels                     = {}
  location                   = "hil"
  name                       = "noios"
  placement_group_id         = 0
  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.noios_ipv4.id
    ipv6_enabled = true
    ipv6         = hcloud_primary_ip.noios_ipv6.id
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
    hcloud_primary_ip.noios_ipv4,
    hcloud_primary_ip.noios_ipv6,
  ]

  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------------------------------------
# vespoid
#
# NixOS server, exposing my private services over Tailscale

resource "hcloud_primary_ip" "vespoid_ipv4" {
  auto_delete       = false
  delete_protection = false
  labels            = {}
  location          = "hil"
  name              = "primary_ip-vespoid-ipv4"
  type              = "ipv4"

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_primary_ip" "vespoid_ipv6" {
  auto_delete       = false
  delete_protection = false
  labels            = {}
  location          = "hil"
  name              = "primary_ip-vespoid-ipv6"
  type              = "ipv6"

  lifecycle {
    prevent_destroy = true
  }
}

resource "hcloud_server" "vespoid" {
  backups                    = true
  delete_protection          = false
  firewall_ids               = []
  ignore_remote_firewall_ids = null
  image                      = "debian-13"
  iso                        = null
  keep_disk                  = null
  labels                     = {}
  location                   = "hil"
  name                       = "vespoid"
  placement_group_id         = 0
  public_net {
    ipv4_enabled = true
    ipv4         = hcloud_primary_ip.vespoid_ipv4.id
    ipv6_enabled = true
    ipv6         = hcloud_primary_ip.vespoid_ipv6.id
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
    hcloud_primary_ip.vespoid_ipv4,
    hcloud_primary_ip.vespoid_ipv6,
  ]

  lifecycle {
    prevent_destroy = true
  }
}
