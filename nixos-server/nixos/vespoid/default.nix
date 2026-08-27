# Machine-specific config for vespoid (Hetzner Cloud VM).
{
  modulesPath,
  ...
}:
{
  imports = [
    # Declarative disk layout
    ./disko.nix

    # KVM guest hardware profile (virtio modules for disk and network)
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  networking.hostName = "vespoid";

  users.users.joni.description = "Vespoid";

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    devices = [ "/dev/sda" ];
  };
}
