# Virt-manager VM management on libvirtd/QEMU.
{
  # QEMU/KVM daemon. The upstream module's polkit rule grants access to
  # the "libvirtd" group.
  virtualisation.libvirtd = {
    enable = true;

    qemu = {
      # Emulated TPM, required by Windows 11.
      swtpm.enable = true;
    };
  };

  # Pass USB devices from the host into VMs through SPICE.
  virtualisation.spiceUSBRedirection.enable = true;

  # Installs virt-manager and autoconnects it to qemu:///system.
  programs.virt-manager.enable = true;
}
