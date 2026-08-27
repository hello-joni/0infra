# Tailscale tailnet resources.

# The tailnet policy file. Singleton resource; the import ID is arbitrary.
resource "tailscale_acl" "this" {
  acl = file("${path.module}/files/tailnet-policy.hujson")

  lifecycle {
    prevent_destroy = true
  }
}
