{ pkgs, ... }: {
  home.packages = with pkgs; [
    nix.man # Manpages for nix, nix-shell, nix.conf, etc.
  ];
}
