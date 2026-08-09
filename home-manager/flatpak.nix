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
    ];

    overrides = {
      # Use GNOME keyring instead of plaintext password store
      "org.signal.Signal".Environment.SIGNAL_PASSWORD_STORE = "gnome-libsecret";
    };
  };
}
