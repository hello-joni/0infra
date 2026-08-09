# Disk layout for paolumu (Lenovo Yoga 7 16IAP7, single NVMe drive).
#
# Single encrypted btrfs partition with subvolumes, unencrypted ESP for
# systemd-boot. Interactive LUKS passphrase at initrd prompt.
#
# Subvolumes can be added later without repartitioning (e.g. @persist for
# impermanence). See https://github.com/nix-community/disko for schema docs.
_: {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # Overridden by disko-install --disk main <device> on install day.
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1024M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "@root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "@swap" = {
                      mountpoint = "/.swapvol";
                      swap.swapfile.size = "16G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
