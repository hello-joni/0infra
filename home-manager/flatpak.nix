{
  services.flatpak = {
    enable = true;
    update = {
      auto.enable = true;
      onActivation = true;
    };
    packages = [
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
      {
        # Keep Chromium around for the odd Firefox-incompatible website
        appId = "org.chromium.Chromium";
        origin = "flathub";
      }
      {
        # Notes app - proprietary ;_;
        appId = "md.obsidian.Obsidian";
        origin = "flathub";
      }
      {
        # Pleasant e-reader
        appId = "com.github.johnfactotum.Foliate";
        origin = "flathub";
      }
      {
        # Office suite
        appId = "org.libreoffice.LibreOffice";
        origin = "flathub";
      }
      {
        # Video player
        appId = "io.mpv.Mpv";
        origin = "flathub";
      }
      {
        # Basic image editing
        appId = "com.github.PintaProject.Pinta";
        origin = "flathub";
      }
      {
        # Companion app for Openterface Mini-KVM
        appId = "com.openterface.openterfaceQT";
        origin = "flathub";
      }
      {
        # Torrent client
        appId = "org.qbittorrent.qBittorrent";
        origin = "flathub";
      }
    ];

    overrides = {
      # Use GNOME keyring instead of plaintext password store
      "org.signal.Signal".Environment.SIGNAL_PASSWORD_STORE = "gnome-libsecret";
    };
  };
}
