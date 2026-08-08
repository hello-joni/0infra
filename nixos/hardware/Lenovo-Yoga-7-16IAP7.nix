# Lenovo Yoga 7 16IAP7 (product code 82QG, 2022)
#
# - Intel Core i7-1260P (Alder Lake-P)
# - Iris Xe graphics
# - https://pcsupport.lenovo.com/us/en/products/laptops-and-netbooks/yoga-series/yoga-7-16iap7/82qg
{
  lib,
  pkgs,
  ...
}:
{
  # SOF bass-speaker fix. See https://wiki.archlinux.org/title/Lenovo_Yoga_7i
  boot.extraModprobeConfig = ''
    options snd-sof-intel-hda-generic hda_model=alc287-yoga9-bass-spk-pin
  '';

  # Intel Iris Xe graphics and hardware video decode.
  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.intel-media-driver ];
  };

  # Accelerometer for tablet-mode screen rotation.
  hardware.sensor.iio.enable = true;

  # GNOME power-profile slider.
  # platform_profile is already loaded by ideapad_laptop on this machine.
  services.power-profiles-daemon.enable = true;

  # LVFS firmware updates.
  services.fwupd.enable = true;
}
