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
      "privacy.resistFingerprinting" = false;
      "identity.fxaccounts.enabled" = true;
    };
  };
}
