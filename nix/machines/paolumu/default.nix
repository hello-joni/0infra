# Machine config for paolumu (Lenovo Yoga 7 16IAP7).
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

    # Hardware config for this laptop model
    ./Lenovo-Yoga-7-16IAP7.nix

    # Steam gaming stack
    ../../modules/nixos/steam.nix
  ];

  networking.hostName = "paolumu";

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
      description = "Paolumu";

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

  # GNOME desktop
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Fish shell: enables vendor completions and man-page completion generation
  programs.fish.enable = true;

  # Tailscale
  services.tailscale.enable = true;

  # Flatpak system daemon and system installation
  services.flatpak.enable = true;

  # Paolumu monster icon resized and padded to 256x256 for the GNOME login screen.
  # Sets the icon via AccountsService activation script.
  system.activationScripts.account-icon.text = ''
    mkdir -p /var/lib/AccountsService/icons
    cp ${
      pkgs.runCommand "paolumu-icon.png"
        {
          nativeBuildInputs = [ pkgs.imagemagick ];
        }
        ''
          convert ${
            builtins.fetchurl {
              url = "https://monsterhunterwiki.org/images/f/f7/MHWI-Paolumu_Icon.png";
              sha256 = "1zh7dvilrx96xy1p6idix4p0dk78jlisrb3dwf222ril1rcvfx4d";
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
