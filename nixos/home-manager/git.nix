{
  pkgs,
  lib,
  ...
}:
{
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = lib.mkDefault "Joni Hendrickson";
        email = lib.mkDefault "contact@joni.site";
      };
      init.defaultBranch = "main";
      core.editor = "vi";
      push.autoSetupRemote = true;
    };
  };
}
