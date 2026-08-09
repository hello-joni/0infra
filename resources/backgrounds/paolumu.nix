{ pkgs }:

let
  raw = builtins.fetchurl {
    url = "https://monsterhunterwiki.org/images/f/f7/MHWI-Paolumu_Icon.png";
    sha256 = "1zh7dvilrx96xy1p6idix4p0dk78jlisrb3dwf222ril1rcvfx4d";
  };
in
pkgs.runCommand "paolumu-background.png"
  {
    nativeBuildInputs = [ pkgs.imagemagick ];
  }
  ''
    convert -size 1920x1080 \
      radial-gradient:'#3a3a3a','#000000' \
      \( ${raw} -resize 200x200 \) \
      -gravity center -composite \
      $out
  ''
