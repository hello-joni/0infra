# Steam gaming stack.
{
  # Mesa userspace drivers and 32-bit libraries, needed by Steam and many games.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Steam. Proton and DXVK are managed by Steam itself at runtime.
  # https://wiki.nixos.org/wiki/Steam
  programs.steam.enable = true;

  # Let games request CPU and scheduling optimizations.
  programs.gamemode.enable = true;
}
