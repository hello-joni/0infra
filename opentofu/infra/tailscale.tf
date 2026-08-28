# Tailscale tailnet resources.

# ---------------------------------------------------------
# ACL
#
# Manages the tailnet policy file, stored in files/tailnet-policy.hujson.

resource "tailscale_acl" "this" {
  acl = file("${path.module}/files/tailnet-policy.hujson")

  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------------------------------------
# DNS

resource "tailscale_dns_preferences" "this" {
  # MagicDNS is on (which matches defaults)
  magic_dns = true

  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------------------------------------
# Tailnet settings

# TODO: Tag servers to prevent them from expiring
# https://tailscale.com/docs/features/session-expiry
# https://tailscale.com/blog/tagged-key-expiry

resource "tailscale_tailnet_settings" "this" {
  # Requires all devices to be authorized after adding them to the tailnet
  devices_approval_on                             = true

  # Defaults:
  devices_key_duration_days                       = 180     # Unmodified default
  devices_auto_updates_on                         = true    # Unmodified default
  users_approval_on                               = false   # Unmodified default
  users_role_allowed_to_join_external_tailnet     = "admin" # Unmodified default
  network_flow_logging_on                         = false   # Unmodified default
  regional_routing_on                             = false   # Unmodified default
  posture_identity_collection_on                  = false   # Unmodified default
  https_enabled                                   = true    # Unmodified default

  lifecycle {
    prevent_destroy = true
  }
}

# ---------------------------------------------------------
# Devices
#
# Each block groups the resources for one device. Tags require
# tagOwners in the ACL, so every tags resource depends on it.

# paolumu: workstation

resource "tailscale_device_authorization" "paolumu" {
  device_id = "6717047417030106"
  authorized = true
}

resource "tailscale_device_tags" "paolumu" {
  device_id = tailscale_device_authorization.paolumu.device_id
  tags      = ["tag:workstation"]

  depends_on = [tailscale_acl.this]
}

# gajau: workstation

resource "tailscale_device_authorization" "gajau" {
  device_id = "6573946740377378"
  authorized = true
}

resource "tailscale_device_tags" "gajau" {
  device_id = tailscale_device_authorization.gajau.device_id
  tags      = ["tag:workstation"]

  depends_on = [tailscale_acl.this]
}

# ginger: workstation

resource "tailscale_device_authorization" "ginger" {
  device_id = "6332351843646902"
  authorized = true
}

resource "tailscale_device_tags" "ginger" {
  device_id = tailscale_device_authorization.ginger.device_id
  tags      = ["tag:workstation"]

  depends_on = [tailscale_acl.this]
}

# wasabi: public-server

resource "tailscale_device_authorization" "wasabi" {
  device_id = "8923626644171409"
  authorized = true
}

resource "tailscale_device_tags" "wasabi" {
  device_id = tailscale_device_authorization.wasabi.device_id
  tags      = ["tag:public-server"]

  depends_on = [tailscale_acl.this]
}

# sh-sassafras: private-server

resource "tailscale_device_authorization" "sh_sassafras" {
  device_id = "4453289642657308"
  authorized = true
}

resource "tailscale_device_tags" "sh_sassafras" {
  device_id = tailscale_device_authorization.sh_sassafras.device_id
  tags      = ["tag:private-server"]

  depends_on = [tailscale_acl.this]
}

# vespoid: private-server

resource "tailscale_device_authorization" "vespoid" {
  device_id = "8404226551818318"
  authorized = true
}

resource "tailscale_device_tags" "vespoid" {
  device_id = tailscale_device_authorization.vespoid.device_id
  tags      = ["tag:private-server"]

  depends_on = [tailscale_acl.this]
}
