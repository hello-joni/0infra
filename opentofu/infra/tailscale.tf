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

resource "tailscale_tailnet_settings" "this" {
  devices_approval_on                             = false
  devices_auto_updates_on                         = true
  # TODO: Tag servers to prevent them from expiring
  # https://tailscale.com/docs/features/session-expiry
  # https://tailscale.com/blog/tagged-key-expiry
  devices_key_duration_days                       = 180
  users_approval_on                               = false
  users_role_allowed_to_join_external_tailnet     = "admin"
  network_flow_logging_on                         = false
  regional_routing_on                             = false
  posture_identity_collection_on                  = false
  https_enabled                                   = true

  lifecycle {
    prevent_destroy = true
  }
}
