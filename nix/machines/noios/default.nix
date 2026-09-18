# Machine config for noios (Hetzner Cloud VM).
{
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    # Shared NixOS base
    ../../modules/nixos/base.nix

    # Declarative disk layout
    ../../modules/nixos/hetzner-disko.nix

    # KVM guest hardware profile (virtio modules for disk and network)
    (modulesPath + "/profiles/qemu-guest.nix")

    ../../modules/nixos/caddy.nix
  ];

  networking.hostName = "noios";

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = [ "/dev/sda" ];
  };

  environment.systemPackages = with pkgs; [
    rsync
    goaccess
  ];

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
      description = "Noios";
      shell = pkgs.bashInteractive;

      # Bootstrap password, only set when the account is first created.
      # Change it with `passwd` after first login.
      initialPassword = "jonipasswd";
      isNormalUser = true;

      # Read access to /var/log/caddy access logs
      extraGroups = [ "caddy" ];
    };
  };

  # ------------------------------------------------------------
  # Tailscale

  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--ssh" ];
  };
}
