{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  # ------------------------------------------------------------
  # NIX CONFIG

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";

  imports = [
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

  # Graphics drivers and 32-bit libraries, needed by Steam and many games.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
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

  users.users = {
    joni = {
      # Fish is entered via exec in fish.nix
      shell = pkgs.bashInteractive;

      # Change password with `passwd` and `sudo passwd root`
      initialPassword = "passwd";
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "video"
        "dialout" # serial port access (Tiny Tapeout FPGA demoboard)
        "plugdev" # Digilent test and measurement devices (Analog Discovery 2)
      ];
    };
  };

  # ------------------------------------------------------------
  # PACKAGES

  allowedUnfreePackages = [
    "steam" # Steam client
    "steam-unwrapped" # Steam client, unwrapped
    "waveforms" # Digilent Oscilloscope
    "adept2-runtime" # Digilent Oscilloscope
  ];

  environment.systemPackages = with pkgs; [
    pciutils
    file
    tree
    jq
    unzip
    zip
    vim
  ];

  # Steam. Proton and DXVK are managed by Steam itself at runtime.
  # https://wiki.nixos.org/wiki/Steam
  programs.steam.enable = true;

  # Let games request CPU and scheduling optimizations.
  programs.gamemode.enable = true;

  # GNOME desktop
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Fish shell: enables vendor completions and man-page completion generation
  programs.fish.enable = true;

  # Tailscale
  services.tailscale.enable = true;

  # Flatpak system daemon and system installation
  services.flatpak.enable = true;
}
