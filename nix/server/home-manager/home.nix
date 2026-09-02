{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
  news.display = "silent";

  home.username = lib.mkDefault "joni";
  home.homeDirectory = lib.mkDefault "/home/joni";

  # Packages that don't fit cleanly into another module
  home.packages = with pkgs; [
    jq
  ];

  # You can import other home-manager modules here
  imports = [
    ../../modules/unfree.nix
    ./fish.nix
    ./git.nix
    ./librechat.nix
  ];
}
