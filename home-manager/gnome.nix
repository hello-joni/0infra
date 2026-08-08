{
  pkgs,
  ...
}: let
  background = import ../resources/backgrounds/paolumu.nix { inherit pkgs; };
in {
  programs.gnome-shell = {
    enable = true;
    extensions = [
      { package = pkgs.gnomeExtensions.dash-to-dock; }
      { package = pkgs.gnomeExtensions.vitals; }
    ];
  };

  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        show-battery-percentage = true;
      };
      "org/gnome/desktop/background" = {
        picture-uri = "file://${background}";
        picture-uri-dark = "file://${background}";
        picture-options = "zoom";
      };
    };
  };
}
