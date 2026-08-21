# Machine-specific config for gajau (Chuwi Minibook X).
{
  pkgs,
  ...
}:
{
  imports = [
    # Auto-generated hardware config (regenerate with --no-filesystems on reinstall)
    ./hardware-configuration.nix
  ];

  networking.hostName = "gajau";

  users.users.joni.description = "Gajau";

  # Gajau monster icon resized and padded to 256x256 for the GNOME login screen.
  # Sets the icon via AccountsService activation script.
  system.activationScripts.account-icon.text = ''
    mkdir -p /var/lib/AccountsService/icons
    cp ${
      pkgs.runCommand "gajau-icon.png"
        {
          nativeBuildInputs = [ pkgs.imagemagick ];
        }
        ''
          convert ${
            builtins.fetchurl {
              url = "https://monsterhunterwiki.org/images/7/73/MHWI-Gajau_Icon.png";
              sha256 = "cECfwlJs1PbwvNszlxZ0TYEYufSdriCU8TxwQD2Z3Ds=";
            }
          } -resize 200x200 -background none -gravity center -extent 256x256+0-10 $out
        ''
    } /var/lib/AccountsService/icons/joni
    chmod 644 /var/lib/AccountsService/icons/joni

    cat > /var/lib/AccountsService/users/joni <<EOF
    [User]
    Icon=/var/lib/AccountsService/icons/joni
    SystemAccount=false
    EOF
  '';
}
