# Machine config for vespoid (Hetzner Cloud VM).
{
  config,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    # Shared NixOS base
    ../../modules/nixos/base.nix

    # Declarative disk layout
    ./disko.nix

    # KVM guest hardware profile (virtio modules for disk and network)
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  networking.hostName = "vespoid";

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = [ "/dev/sda" ];
  };

  # ------------------------------------------------------------
  # SYSTEM CONFIG

  # Home Manager as a NixOS module
  home-manager.useUserPackages = true;
  home-manager.users.joni = import ./home.nix;

  users.users = {
    root = {
      # Bootstrap password, only set when the account is first created.
      # Change it with `passwd` after first login.
      initialPassword = "rootpasswd";
    };

    joni = {
      description = "Vespoid";

      # Fish is entered via exec in fish.nix
      shell = pkgs.bashInteractive;

      # Bootstrap password, only set when the account is first created.
      # Change it with `passwd` after first login.
      initialPassword = "jonipasswd";
      isNormalUser = true;

      # Linger keeps the user systemd manager running so the containers
      # survive without a login session.
      linger = true;
    };
  };

  # ------------------------------------------------------------
  # PACKAGES

  # Fish shell: enables vendor completions and man-page completion generation
  programs.fish.enable = true;

  # Tailscale
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    extraSetFlags = [ "--ssh" ];
  };

  # ------------------------------------------------------------
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
