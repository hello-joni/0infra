{
  pkgs,
  machine,
  ...
}:
let
  # Monster icon composited over a radial gradient for the GNOME desktop background.
  mkBackground =
    name: iconUrl: iconSha256:
    pkgs.runCommand "${name}-background.png"
      {
        nativeBuildInputs = [ pkgs.imagemagick ];
      }
      ''
        convert -size 1920x1080 \
          radial-gradient:'#3a3a3a','#000000' \
          \( ${
            builtins.fetchurl {
              url = iconUrl;
              sha256 = iconSha256;
            }
          } -resize 200x200 \) \
          -gravity center -composite \
          $out
      '';

  backgrounds = {
    paolumu = mkBackground "paolumu"
      "https://monsterhunterwiki.org/images/f/f7/MHWI-Paolumu_Icon.png"
      "1zh7dvilrx96xy1p6idix4p0dk78jlisrb3dwf222ril1rcvfx4d";
    gajau = mkBackground "gajau"
      "https://monsterhunterwiki.org/images/7/73/MHWI-Gajau_Icon.png"
      "cECfwlJs1PbwvNszlxZ0TYEYufSdriCU8TxwQD2Z3Ds=";
  };

  background = backgrounds.${machine};
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
        clock-show-weekday = true;
      };
      "org/gnome/desktop/notifications" = {
        show-banners = true;
      };
      "org/gnome/shell/extensions/dash-to-dock" = {
        show-icons-emblems = false;
      };
      "org/gnome/settings-daemon/plugins/color" = {
        night-light-enabled = true;
        night-light-schedule-automatic = false;
        # Fractional hours in 24-hour time: 20.0 = 8pm, 6.0 = 6am.
        night-light-schedule-from = 20.0;
        night-light-schedule-to = 6.0;
      };
      "org/gnome/desktop/background" = {
        picture-uri = "file://${background}";
        picture-uri-dark = "file://${background}";
        picture-options = "zoom";
      };
    };
  };
}
