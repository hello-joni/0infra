# Machine config for gajau (Chuwi Minibook X).
{
  pkgs,
  ...
}:
{
  imports = [
    # Shared NixOS base
    ../../modules/nixos/base.nix

    # Auto-generated hardware config (regenerate with --no-filesystems on reinstall)
    ./hardware-configuration.nix

    # Steam gaming stack
    ../../modules/nixos/steam.nix
  ];

  networking.hostName = "gajau";

  # ------------------------------------------------------------
  # SYSTEM CONFIG

  # Bootloader config
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Home Manager as a NixOS module
  home-manager.useUserPackages = true;
  home-manager.users.joni = import ./home.nix;

  users.users = {
    joni = {
      description = "Gajau";

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

  # GNOME desktop
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Fish shell: enables vendor completions and man-page completion generation
  programs.fish.enable = true;

  # Tailscale
  services.tailscale.enable = true;

  # Flatpak system daemon and system installation
  services.flatpak.enable = true;

  # Gajau monster icon resized and padded to 256x256 for the GNOME login screen.
  # Sets the icon via AccountsService activation script.
  system.activationScripts.account-icon.text = ''
    mkdir -p /var/lib/AccountsService/icons
    cp ${
      pkgs.runCommand "gajau-icon.png"
        {
          nativeBuildInputs = [ pkgs.imagemagick ];
        }
        ''
          convert ${
            builtins.fetchurl {
              url = "https://monsterhunterwiki.org/images/7/73/MHWI-Gajau_Icon.png";
              sha256 = "cECfwlJs1PbwvNszlxZ0TYEYufSdriCU8TxwQD2Z3Ds=";
            }
          } -resize 200x200 -background none -gravity center -extent 256x256+0-10 $out
        ''
    } /var/lib/AccountsService/icons/joni
    chmod 644 /var/lib/AccountsService/icons/joni

    cat > /var/lib/AccountsService/users/joni <<EOF
    [User]
    Icon=/var/lib/AccountsService/icons/joni
    SystemAccount=false
    EOF
  '';
}
