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
              echo "Run: secret-tool store --label='Hetzner Cloud API token' service hcloud-token" >&2
              exit 1
            fi
            export HCLOUD_TOKEN
            AWS_ACCESS_KEY_ID="$(${pkgs.libsecret}/bin/secret-tool lookup service hetzner-s3-access 2>/dev/null || true)"
            if [ -z "''${AWS_ACCESS_KEY_ID:-}" ]; then
              echo "Hetzner Object Storage access key not found in the GNOME Keyring." >&2
              echo "Run: secret-tool store --label='Hetzner Object Storage access key' service hetzner-s3-access" >&2
              exit 1
            fi
            export AWS_ACCESS_KEY_ID
            AWS_SECRET_ACCESS_KEY="$(${pkgs.libsecret}/bin/secret-tool lookup service hetzner-s3-secret 2>/dev/null || true)"
            if [ -z "''${AWS_SECRET_ACCESS_KEY:-}" ]; then
              echo "Hetzner Object Storage secret key not found in the GNOME Keyring." >&2
              echo "Run: secret-tool store --label='Hetzner Object Storage secret key' service hetzner-s3-secret" >&2
              exit 1
            fi
            export AWS_SECRET_ACCESS_KEY
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
