# Caddy webserver for the personal site.
let
  domain = "joni.site";
in
{
  services.caddy = {
    enable = true;
    email = "contact@joni.site";
    openFirewall = true;

    virtualHosts.${domain}.extraConfig = ''
      root * /var/www/${domain}
      file_server
      encode zstd gzip
      header {
        -Server
        Strict-Transport-Security "max-age=31536000; includeSubDomains"
        X-Content-Type-Options nosniff
        Referrer-Policy strict-origin-when-cross-origin
        Cache-Control "public, max-age=3600"
      }
    '';

    # TODO: Modify the static site generator to emit br and gzip files,
    # then restore `precompressed br gzip` on file_server.
    virtualHosts."www.${domain}".extraConfig = ''
      redir https://${domain}{uri} permanent
    '';
  };

  systemd.tmpfiles.rules = [
    "d /var/www/${domain} 0755 joni root"
  ];
}
