# Run the following command to get a device's syncthing ID without syncthing enabled:
# nix shell nixpkgs#syncthing -c syncthing generate --home ~/.config/syncthing
let
  devices = {
    # Phone (GrapheneOS)
    ginger.id = "7WVHCQA-KDJACMV-GRC3MUB-PXSWAVD-7PU5ZV2-UXAMIOM-KZUOMLX-FF3MAAI";

    # Large Laptop
    paolumu.id = "P5Q5IG6-RRBLRQF-2DB634X-JSCAFMZ-T42MUBN-WI3F7R6-YFWHYCO-TM5CWAT";

    # Mini Laptop
    gajau.id = "RTFI3R2-AQMT7VM-QOJ2FXR-WNJZTL2-VSYFHSC-2XWEVOA-RFA6KHK-5JXSWQE";

    # Selfhost server
    vespoid.id = "YAFQL6B-X6GJIVS-GNI3S3I-BACKHJJ-G5WQAFL-S6RW3WK-2WBR3BO-ML76XQL";

    # Legacy selfhost server (currently replacing)
    sh-sassafras.id = "4PJJBRC-HM7M4I7-FUZYMAP-3XXJ5P5-UHDIY67-NA5X53V-UW7H2IF-PMISLAB";
  };

  deviceNames = builtins.attrNames devices;

  # Shared folder settings.
  mkSyncthingFolder = id: {
    inherit id;
    order = "newest";
    ignorePerms = true;
    versioning = {
      type = "staggered";
      params.maxAge = "2592000"; # 30 days in seconds
    };
    devices = deviceNames;
  };
in
{
  services.syncthing = {
    enable = true;
    settings = {
      inherit devices;
      folders."~/0everything" = mkSyncthingFolder "0everything";
      folders."~/0logseq" = mkSyncthingFolder "0logseq";
      folders."~/0llm" = mkSyncthingFolder "0notes";
    };
  };
}
