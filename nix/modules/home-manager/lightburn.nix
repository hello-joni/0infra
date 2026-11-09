# LightBurn laser cutter control software (https://lightburnsoftware.com).
# Unfree, binary-only, x86_64-linux. Imported by paolumu only.
{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.lightburn ];

  allowedUnfreePackages = [ "lightburn" ];
}
