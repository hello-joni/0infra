# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # You can import other NixOS modules here
  imports = [
    # Auto-generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # NixOS-only modules
    ./nixos-modules/account-icon.nix
    ./nixos-modules/hardware/Lenovo-Yoga-7-16IAP7.nix

    # Shared modules
    ../modules/unfree.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = false;
    };
  };

  nix = {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      flake-registry = "";
    };
    # Opinionated: disable channels
    channel.enable = false;
  };

  # Home Manager as a NixOS module
  home-manager.useUserPackages = true;
  home-manager.users.joni = import ../home-manager/home.nix;

  networking.hostName = "paolumu";

  users.users = {
    joni = {
      # Shows on login page
      description = "Paolumu";

      # Fish is entered via exec in fish.nix
      shell = pkgs.bashInteractive;

      # Change password with `passwd` and `sudo passwd root`
      initialPassword = "passwd";
      isNormalUser = true;
      extraGroups = ["wheel" "video"];
    };
  };

  # User icon
  services.account-icon = {
    enable = true;
    user = "joni";
    image = import ../resources/icons/paolumu.nix { inherit pkgs; };
  };


  # Packages

  # GNOME desktop
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.gnome.core-apps.enable = false;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-user-docs
  ];

  environment.systemPackages = with pkgs; [
    gnome-terminal
    nautilus
    pciutils
  ];

  # Fish shell: enables vendor completions and man-page completion generation
  programs.fish.enable = true;

  # Tailscale
  services.tailscale.enable = true;

}
