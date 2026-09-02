# Machine-specific config for paolumu (Lenovo Yoga 7 16IAP7).
{
  pkgs,
  ...
}:
{
  imports = [
    # Auto-generated hardware config (regenerate with --no-filesystems on reinstall)
    ./hardware-configuration.nix

    # Hardware config for this laptop model
    ./Lenovo-Yoga-7-16IAP7.nix
  ];

  networking.hostName = "paolumu";

  users.users.joni.description = "Paolumu";

  # Paolumu monster icon resized and padded to 256x256 for the GNOME login screen.
  # Sets the icon via AccountsService activation script.
  system.activationScripts.account-icon.text = ''
    mkdir -p /var/lib/AccountsService/icons
    cp ${
      pkgs.runCommand "paolumu-icon.png"
        {
          nativeBuildInputs = [ pkgs.imagemagick ];
        }
        ''
          convert ${
            builtins.fetchurl {
              url = "https://monsterhunterwiki.org/images/f/f7/MHWI-Paolumu_Icon.png";
              sha256 = "1zh7dvilrx96xy1p6idix4p0dk78jlisrb3dwf222ril1rcvfx4d";
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
