_:

{
  # Add new machines here when I'm done configuring them and update other configs
  services.syncthing = {
    enable = true;
    settings = {
      devices = {
        # Phone (GrapheneOS)
        ginger.id = "7WVHCQA-KDJACMV-GRC3MUB-PXSWAVD-7PU5ZV2-UXAMIOM-KZUOMLX-FF3MAAI";

        # Laptop
        paolumu.id = "P5Q5IG6-RRBLRQF-2DB634X-JSCAFMZ-T42MUBN-WI3F7R6-YFWHYCO-TM5CWAT";

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
          "paolumu"
          "sh-sassafras"
        ];
      };
      folders."~/0logseq" = {
        id = "0logseq";
        order = "newest";
        ignorePerms = true;
        versioning = {
          type = "staggered";
          params.maxAge = "31536000";
        };
        devices = [
          "ginger"
          "paolumu"
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
          "paolumu"
          "sh-sassafras"
        ];
      };
    };
  };
}
