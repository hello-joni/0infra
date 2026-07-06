_:

{
  # Add new machines here when I'm done configuring them and update other configs
  services.syncthing = {
    enable = true;
    settings = {
      devices = {
        # Phone (introducer, since its config isn't managed by Nix anyways)
        ginger = {
          id = "ROA5SZQ-OA33NRK-2NNBO5R-QVVW3FQ-DBFUWP6-XTQ4UKJ-M2D66T6-UAFPFAQ";
          introducer = true;
        };

        # Laptop
        saffron.id = "T2F7ICT-EMNBQH6-TBDQ4DE-7X7J57J-QCGWIS2-VXBN4HB-LRGNZUZ-AFI5IQF";

        # Selfhost server
        sh-sassafras.id = "4PJJBRC-HM7M4I7-FUZYMAP-3XXJ5P5-UHDIY67-NA5X53V-UW7H2IF-PMISLAB";

        # Test Android phone (for app testing only, not synced with main devices)
        test-phone.id = "F2TFKUJ-LJIUVIX-UUUPDQN-I55RADE-R6TFI4O-5UOHD3T-RLTMVKR-X2SV5QG";
      };
      folders."~/0everything" = {
        id = "0everything";
        order = "newest";
        ignorePerms = true;
        versioning = {
          type = "staggered";
          params.maxAge = "31536000"; # 1 year in seconds
        };
        devices = [
          "ginger"
          "saffron"
          "sh-sassafras"
        ];
      };
      folders."~/0notes" = {
        id = "0notes";
        order = "newest";
        ignorePerms = true;
        versioning = {
          type = "staggered";
          params.maxAge = "31536000"; # 1 year in seconds
        };
        devices = [
          "ginger"
          "saffron"
          "sh-sassafras"
        ];
      };
    };
  };
}
