{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # ------------------------------------------------------------
  # NIX CONFIG

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";

  imports = [
    # Auto-generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix

    # NixOS-only modules
    ./modules/account-icon.nix
    ./hardware/Lenovo-Yoga-7-16IAP7.nix

    # Shared modules
    ../modules/unfree.nix
  ];

  nixpkgs = {
    config = {
      # Unfree packages are handled with 0nix/modules/unfree.nix by declaring:
      # config.allowedUnfreePackages = [ "foo-pkg" "bar-pkg" ];
      allowUnfree = false;
    };
  };

  nix = {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Disable global registry
      flake-registry = "";
    };
    # Disable channels
    channel.enable = false;
  };

  # ------------------------------------------------------------
  # SYSTEM CONFIG

  # Bootloader config
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

  # ------------------------------------------------------------
  # PACKAGES

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
