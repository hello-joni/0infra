# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
  news.display = "silent";

  home.username = lib.mkDefault "joni";
  home.homeDirectory = lib.mkDefault "/home/joni";

  programs.git.enable = true;

  # You can import other home-manager modules here
  imports = [
    ./librewolf.nix
  ];
}
