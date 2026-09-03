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

# All devices that appear on the tailnet must be either:
# - Manually authorized and tagged by adding them to this list
# - Removed from the tailnet altogether as unauthorized
locals {
  device_roster = {
    paolumu = {
      id   = "6717047417030106"
      tags = ["tag:client"]
    }
    gajau = {
      id   = "6573946740377378"
      tags = ["tag:client"]
    }
    ginger = {
      id   = "6332351843646902"
      tags = ["tag:client"]
    }
    vespoid = {
      id   = "4453289642657308"
      tags = ["tag:server"]
    }
    wasabi = {
      id   = "8923626644171409"
      tags = ["tag:server"]
    }
  }
}

resource "tailscale_device_authorization" "device" {
  for_each  = local.device_roster
  device_id = each.value.id
  authorized = true
}

# Tags must have an owner in the ACL's tagOwners before they can be applied.
resource "tailscale_device_tags" "device" {
  for_each  = local.device_roster
  device_id = each.value.id
  tags      = each.value.tags

  depends_on = [tailscale_acl.this]
}

data "tailscale_devices" "all" {
  lifecycle {
    # Catches devices that joined the tailnet without a roster entry.
    postcondition {
      condition = length([
        for d in self.devices :
        d.id if !contains([for name, dev in local.device_roster : dev.id], d.id)
      ]) == 0
      error_message = "Unmanaged devices on the tailnet: ${join(", ", [for d in self.devices : d.name if !contains([for name, dev in local.device_roster : dev.id], d.id)])}. Add them to local.device_roster."
    }

    # Catches roster entries whose device left the tailnet.
    postcondition {
      condition = length([
        for name, d in local.device_roster :
        name if !contains([for dev in self.devices : dev.id], d.id)
      ]) == 0
      error_message = "Roster devices missing from the tailnet: ${join(", ", [for name, d in local.device_roster : name if !contains([for dev in self.devices : dev.id], d.id)])}. Remove them from local.device_roster."
    }
  }
}
