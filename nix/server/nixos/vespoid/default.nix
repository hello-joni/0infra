# Machine-specific config for vespoid (Hetzner Cloud VM).
{
  config,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    # Declarative disk layout
    ./disko.nix

    # KVM guest hardware profile (virtio modules for disk and network)
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  networking.hostName = "vespoid";

  users.users.joni.description = "Vespoid";

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = [ "/dev/sda" ];
  };

  # Linger keeps the user systemd manager running so the containers
  # survive without a login session.
  users.users.joni.linger = true;

  # ---------------------------------------------------------
  # LibreChat

  # The services.tailscale.serve module cannot currently serve https,
  # so an activation script uses `tailscale serve --bg` instead.
  # https://github.com/tailscale/tailscale/issues/18381
  systemd.services.librechat-tailscale-serve = {
    description = "Tailscale serve proxy for LibreChat";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ config.services.tailscale.package ];
    script = ''
      tailscale serve --bg http://127.0.0.1:3080
    '';
  };
}
