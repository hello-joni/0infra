_:

{
  # Add new machines here when I'm done configuring them and update other configs
  services.syncthing = {
    enable = true;
    settings = {
      devices = {
        # Phone (introducer, since its config isn't managed by Nix anyways)
        ginger = {
          id = "7WVHCQA-KDJACMV-GRC3MUB-PXSWAVD-7PU5ZV2-UXAMIOM-KZUOMLX-FF3MAAI";
          introducer = true;
        };

        # Laptop
        saffron.id = "T2F7ICT-EMNBQH6-TBDQ4DE-7X7J57J-QCGWIS2-VXBN4HB-LRGNZUZ-AFI5IQF";

        # Selfhost server
        sh-sassafras.id = "4PJJBRC-HM7M4I7-FUZYMAP-3XXJ5P5-UHDIY67-NA5X53V-UW7H2IF-PMISLAB";
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
