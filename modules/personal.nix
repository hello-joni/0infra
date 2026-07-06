{
  config,
  pkgs,
  ...
}:

let
  # The home-manager podman module hardcodes PATH without /usr/bin, where shadow-utils
  # provides newuidmap/newgidmap on Fedora Silverblue. Override with a stable-path PATH.
  rootlessPath = "PATH=/run/wrappers/bin:/run/current-system/sw/bin:/usr/bin:${config.home.homeDirectory}/.nix-profile/bin";
in

{
  home.packages = with pkgs; [
    (config.lib.nixGL.wrap subsurface) # Dive log software
    gh
  ];

  dconf.settings."org/gnome/shell" = {
    favorite-apps = [
      "io.gitlab.librewolf-community.desktop"
      "org.gnome.Nautilus.desktop"
      "org.gnome.Ptyxis.desktop"
      "dev.zed.Zed.desktop"
      "md.obsidian.Obsidian.desktop"
    ];
  };

  services.flatpak.packages = [
    {
      # Personal finance
      appId = "com.actualbudget.actual";
      origin = "flathub";
    }
    {
      # Chat app - Matrix client
      appId = "im.fluffychat.Fluffychat";
      origin = "flathub";
    }
    {
      # Chat app - Signal desktop
      appId = "org.signal.Signal";
      origin = "flathub";
    }
    {
      # Chat app - proprietary ;_;
      appId = "com.discordapp.Discord";
      origin = "flathub";
    }
    {
      # Streaming service aggregator
      appId = "com.stremio.Stremio";
      origin = "flathub";
    }
    {
      # Flashcards
      appId = "net.ankiweb.Anki";
      origin = "flathub";
    }
  ];

  services.flatpak.overrides = {
    # Use GNOME keyring instead of plaintext password store
    "org.signal.Signal".Environment.SIGNAL_PASSWORD_STORE = "gnome-libsecret";
  };

  # Local SilverBullet instance bound to ~/0notes. Intended as a per-machine text editor
  # over the notes tree, not a synced space like the selfhost profile's silverbullet.
  services.podman = {
    enable = true;
    autoUpdate = {
      enable = true;
      onCalendar = "Sun *-*-* 04:00:00";
    };

    containers.silverbullet = {
      image = "ghcr.io/silverbulletmd/silverbullet:latest";
      autoStart = true;
      autoUpdate = "registry";
      ports = [ "127.0.0.1:1234:3000" ];
      volumes = [ "${config.home.homeDirectory}/0notes:/space:Z" ];
      # The home-manager podman module hardcodes PATH without /usr/bin, where shadow-utils
      # provides newuidmap/newgidmap on Fedora Silverblue. Override with a stable-path PATH.
      extraConfig.Service.Environment = rootlessPath;
    };
  };

  # The podman module's auto-update service also hardcodes PATH without /usr/bin.
  systemd.user.services."podman-auto-update".Service.Environment = rootlessPath;
}
