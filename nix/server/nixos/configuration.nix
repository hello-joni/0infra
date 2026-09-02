{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  # ------------------------------------------------------------
  # NIX CONFIG

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";

  imports = [
    # Shared modules
    ../../modules/unfree.nix
  ];

  nixpkgs = {
    config = {
      # Unfree packages are handled with nix/modules/unfree.nix by declaring:
      # config.allowedUnfreePackages = [ "foo-pkg" "bar-pkg" ];
      allowUnfree = false;
    };
  };

  nix = {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Disable global registry
      flake-registry = "";
    };
    # Disable channels
    channel.enable = false;
  };

  # ------------------------------------------------------------
  # SYSTEM CONFIG

  # Home Manager as a NixOS module
  home-manager.useUserPackages = true;
  home-manager.users.joni = import ../home-manager/home.nix;

  users.users = {
    root = {
      # Bootstrap password, only set when the account is first created.
      # Change it with `passwd` after first login.
      initialPassword = "rootpasswd";
    };

    joni = {
      # Fish is entered via exec in fish.nix
      shell = pkgs.bashInteractive;

      # Bootstrap password, only set when the account is first created.
      # Change it with `passwd` after first login.
      initialPassword = "jonipasswd";
      isNormalUser = true;
    };
  };

  # ------------------------------------------------------------
  # PACKAGES

  environment.systemPackages = with pkgs; [
    file
    tree
    jq
    vim
  ];

  # Fish shell: enables vendor completions and man-page completion generation
  programs.fish.enable = true;

  # Tailscale
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    extraSetFlags = [ "--ssh" ];
  };
}
