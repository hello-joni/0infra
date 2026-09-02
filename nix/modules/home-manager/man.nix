{ pkgs, ... }: {
  # Documentation
  programs.man = {
    enable = true;
    generateCaches = true;
  };
  programs.info.enable = true;

  home.packages = with pkgs; [
    nix.man # Manpages for nix, nix-shell, nix.conf, etc.
  ];
}
