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

  # You can import other home-manager modules here
  imports = [
    ../modules/unfree.nix
    ./fish.nix
    ./flatpak.nix
    ./gnome.nix
    ./librewolf.nix
    ./man.nix
    ./scripts.nix
    ./direnv.nix
    ./syncthing.nix
    ./zed.nix
    ./git.nix
  ];
}
