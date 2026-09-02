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
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
    ../../modules/unfree.nix
    ../../modules/home-manager/fish.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/man.nix
    ../../modules/home-manager/scripts.nix
    ../../modules/home-manager/syncthing.nix
    ../../modules/home-manager/flatpak.nix
    ../../modules/home-manager/gnome.nix
    ../../modules/home-manager/librewolf.nix
    ../../modules/home-manager/direnv.nix
    ../../modules/home-manager/zed.nix
    ../../modules/home-manager/github.nix
    # ../../modules/home-manager/zephyr.nix
  ];
}
