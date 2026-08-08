{ lib, config, ... }:

let
  cfg = config.services.account-icon;
in
{
  options.services.account-icon = {
    enable = lib.mkEnableOption "user icon via AccountsService";

    user = lib.mkOption {
      type = lib.types.str;
      description = "Username to set the icon for";
    };

    image = lib.mkOption {
      type = lib.types.package;
      description = "Image derivation to use as the user icon";
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.account-icon.text = ''
      mkdir -p /var/lib/AccountsService/icons
      cp ${cfg.image} /var/lib/AccountsService/icons/${cfg.user}
      chmod 644 /var/lib/AccountsService/icons/${cfg.user}

      cat > /var/lib/AccountsService/users/${cfg.user} <<EOF
      [User]
      Icon=/var/lib/AccountsService/icons/${cfg.user}
      SystemAccount=false
      EOF
    '';
  };
}
