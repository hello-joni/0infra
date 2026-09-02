# Shared NixOS base. Machine-specific config lives in each machine dir.
{
  pkgs,
  ...
}:
{
  imports = [ ../unfree.nix ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";

  nixpkgs.config = {
    # Unfree packages are handled with nix/modules/unfree.nix by declaring:
    # config.allowedUnfreePackages = [ "foo-pkg" "bar-pkg" ];
    allowUnfree = false;
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

  # Common packages
  environment.systemPackages = with pkgs; [
    pciutils
    file
    tree
    jq
    unzip
    zip
    vim
  ];
}
