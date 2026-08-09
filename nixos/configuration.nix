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
    # Auto-generated hardware config (regenerate with --no-filesystems on reinstall)
    ./hardware-configuration.nix

    # Hardware config for this laptop model
    ./Lenovo-Yoga-7-16IAP7.nix

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
  # ACCOUNT ICON

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
      extraGroups = [
        "wheel"
        "video"
      ];
    };
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
    vim # provides vi
  ];

  # Fish shell: enables vendor completions and man-page completion generation
  programs.fish.enable = true;

  # Tailscale
  services.tailscale.enable = true;

  # Flatpak system daemon and system installation
  services.flatpak.enable = true;
}


