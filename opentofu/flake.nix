{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs:
        let
          # Wraps tofu so that provider and backend credentials are pulled from
          # the GNOME Keyring at launch, keeping secrets out of the repo and the
          # world-readable Nix store. Store the secrets once per machine (see
          # README.md).
          tofu-wrapped = pkgs.writeShellScriptBin "tofu" ''
            set -euo pipefail
            HCLOUD_TOKEN="$(${pkgs.libsecret}/bin/secret-tool lookup service hcloud-token 2>/dev/null || true)"
            if [ -z "''${HCLOUD_TOKEN:-}" ]; then
              echo "Hetzner Cloud API token not found in the GNOME Keyring." >&2
              echo "" >&2
              echo "secret-tool store --label='Hetzner Cloud API token' service hcloud-token" >&2
              echo "" >&2
              exit 1
            fi
            export HCLOUD_TOKEN
            AWS_ACCESS_KEY_ID="$(${pkgs.libsecret}/bin/secret-tool lookup service hetzner-s3-access 2>/dev/null || true)"
            if [ -z "''${AWS_ACCESS_KEY_ID:-}" ]; then
              echo "Hetzner Object Storage access key not found in the GNOME Keyring." >&2
              echo "" >&2
              echo "secret-tool store --label='Hetzner Object Storage access key' service hetzner-s3-access" >&2
              echo "" >&2
              exit 1
            fi
            export AWS_ACCESS_KEY_ID
            AWS_SECRET_ACCESS_KEY="$(${pkgs.libsecret}/bin/secret-tool lookup service hetzner-s3-secret 2>/dev/null || true)"
            if [ -z "''${AWS_SECRET_ACCESS_KEY:-}" ]; then
              echo "Hetzner Object Storage secret key not found in the GNOME Keyring." >&2
              echo "" >&2
              echo "secret-tool store --label='Hetzner Object Storage secret key' service hetzner-s3-secret" >&2
              echo "" >&2
              exit 1
            fi
            export AWS_SECRET_ACCESS_KEY
            DNSIMPLE_TOKEN="$(${pkgs.libsecret}/bin/secret-tool lookup service dnsimple-token 2>/dev/null || true)"
            if [ -z "''${DNSIMPLE_TOKEN:-}" ]; then
              echo "DNSimple API token not found in the GNOME Keyring." >&2
              echo "" >&2
              echo "secret-tool store --label='DNSimple API token' service dnsimple-token" >&2
              echo "" >&2
              exit 1
            fi
            export DNSIMPLE_TOKEN
            DNSIMPLE_ACCOUNT="$(${pkgs.libsecret}/bin/secret-tool lookup service dnsimple-account 2>/dev/null || true)"
            if [ -z "''${DNSIMPLE_ACCOUNT:-}" ]; then
              echo "DNSimple account ID not found in the GNOME Keyring." >&2
              echo "" >&2
              echo "secret-tool store --label='DNSimple account ID' service dnsimple-account" >&2
              echo "" >&2
              exit 1
            fi
            export DNSIMPLE_ACCOUNT
            TAILSCALE_OAUTH_CLIENT_ID="$(${pkgs.libsecret}/bin/secret-tool lookup service tailscale-oauth-client-id 2>/dev/null || true)"
            if [ -z "''${TAILSCALE_OAUTH_CLIENT_ID:-}" ]; then
              echo "Tailscale OAuth client ID not found in the GNOME Keyring." >&2
              echo "" >&2
              echo "secret-tool store --label='Tailscale OAuth client ID' service tailscale-oauth-client-id" >&2
              echo "" >&2
              exit 1
            fi
            export TAILSCALE_OAUTH_CLIENT_ID
            TAILSCALE_OAUTH_CLIENT_SECRET="$(${pkgs.libsecret}/bin/secret-tool lookup service tailscale-oauth-client-secret 2>/dev/null || true)"
            if [ -z "''${TAILSCALE_OAUTH_CLIENT_SECRET:-}" ]; then
              echo "Tailscale OAuth client secret not found in the GNOME Keyring." >&2
              echo "" >&2
              echo "secret-tool store --label='Tailscale OAuth client secret' service tailscale-oauth-client-secret" >&2
              echo "" >&2
              exit 1
            fi
            export TAILSCALE_OAUTH_CLIENT_SECRET
            # PII for contact resources, passed as TF_VAR_* variables.
            # Empty values are allowed; store an empty secret if a field
            # does not apply.
            for pii_var in pii_email pii_address pii_city pii_state pii_postal_code pii_country pii_first_name pii_last_name pii_middle_name pii_phone; do
              pii_value="$(${pkgs.libsecret}/bin/secret-tool lookup service "$pii_var" 2>/dev/null || true)"
              if [ -z "''${pii_value:-}" ]; then
                echo "PII value '$pii_var' not found in the GNOME Keyring." >&2
                echo "" >&2
                echo "secret-tool store --label='$pii_var' service $pii_var" >&2
                echo "" >&2
                exit 1
              fi
              export TF_VAR_"$pii_var"="$pii_value"
            done
            exec ${pkgs.opentofu}/bin/tofu "$@"
          '';
        in
        {
          default = pkgs.mkShell {
            packages = [
              tofu-wrapped
              pkgs.opentofu
              pkgs.hcloud
              pkgs.libsecret
            ];
          };
        });
    };
}
