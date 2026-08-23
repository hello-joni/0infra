{
  services.syncthing = {
    enable = true;
    settings = {
      devices = {
        # Phone (GrapheneOS)
        ginger.id = "7WVHCQA-KDJACMV-GRC3MUB-PXSWAVD-7PU5ZV2-UXAMIOM-KZUOMLX-FF3MAAI";

        # Large Laptop
        saffron.id = "T2F7ICT-EMNBQH6-TBDQ4DE-7X7J57J-QCGWIS2-VXBN4HB-LRGNZUZ-AFI5IQF";

        # Mini Laptop
        gajau.id = "RTFI3R2-AQMT7VM-QOJ2FXR-WNJZTL2-VSYFHSC-2XWEVOA-RFA6KHK-5JXSWQE";

        # Selfhost server
        sh-sassafras.id = "4PJJBRC-HM7M4I7-FUZYMAP-3XXJ5P5-UHDIY67-NA5X53V-UW7H2IF-PMISLAB";

        # Work laptop
        fenugreek.id = "BGTQMFS-6SWFN75-BFTUL5R-4HLMHMG-RZD2ZDQ-EWOD45C-PAOROHK-3UXWFAA";
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
          "gajau"
          "sh-sassafras"
        ];
      };

      folders."~/0llm" = {
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
          "gajau"
          "sh-sassafras"
          "fenugreek"
        ];
      };
    };
  };
}
