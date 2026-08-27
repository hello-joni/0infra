# Providers required by the infra module. Provider configuration
# (credentials, tailnet) is inherited from the root module.

terraform {
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
