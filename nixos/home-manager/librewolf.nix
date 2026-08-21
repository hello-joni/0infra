{
  pkgs,
  lib,
  ...
}:
{
  programs.librewolf = {
    enable = true;
    policies = {
      DisableFirefoxAccounts = false;
    };
    settings = {
      "webgl.disabled" = false;
      "librewolf.webgl.prompt" = false;
      "privacy.resistFingerprinting" = false;
      "identity.fxaccounts.enabled" = true;
    };
  };
}
