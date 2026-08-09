{ pkgs }:

let
  raw = builtins.fetchurl {
    url = "https://monsterhunterwiki.org/images/f/f7/MHWI-Paolumu_Icon.png";
    sha256 = "1zh7dvilrx96xy1p6idix4p0dk78jlisrb3dwf222ril1rcvfx4d";
  };
in
pkgs.runCommand "paolumu-icon.png"
  {
    nativeBuildInputs = [ pkgs.imagemagick ];
  }
  ''
    convert ${raw} -resize 200x200 -background none -gravity center -extent 256x256+0-10 $out
  ''
