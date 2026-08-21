{
  pkgs,
  ...
}:
let
  # Paolumu monster icon composited over a radial gradient for the GNOME desktop background.
  background =
    pkgs.runCommand "paolumu-background.png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        convert -size 1920x1080 \
          radial-gradient:'#3a3a3a','#000000' \
          \( ${
            builtins.fetchurl {
              url = "https://monsterhunterwiki.org/images/f/f7/MHWI-Paolumu_Icon.png";
              sha256 = "1zh7dvilrx96xy1p6idix4p0dk78jlisrb3dwf222ril1rcvfx4d";
            }
          } -resize 200x200 \) \
          -gravity center -composite \
          $out
      '';
in
{
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
      "org/gnome/desktop/notifications" = {
        show-banners = true;
      };
      "org/gnome/shell/extensions/dash-to-dock" = {
        show-icons-emblems = false;
      };
      "org/gnome/desktop/background" = {
        picture-uri = "file://${background}";
        picture-uri-dark = "file://${background}";
        picture-options = "zoom";
      };
    };
  };
}
