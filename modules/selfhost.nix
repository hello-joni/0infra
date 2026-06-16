{
  config,
  lib,
  ...
}:

let
  librechatDir = "${config.home.homeDirectory}/0selfhost/librechat";

  # These are not real secrets. On a Tailscale-only single-user instance,
  # they just need to exist and stay consistent across restarts.
  credsKey = "0000000000000000000000000000000000000000000000000000000000000001";
  credsIv = "00000000000000000000000000000002";
  jwtSecret = "0000000000000000000000000000000000000000000000000000000000000003";
  jwtRefreshSecret = "0000000000000000000000000000000000000000000000000000000000000004";
  meiliMasterKey = "not-a-real-secret-on-tailnet";

  librechatYaml = builtins.toFile "librechat.yaml" ''
    version: 1.3.5
    cache: true

    endpoints:
      custom:
        - name: "OpenRouter"
          apiKey: "''${OPENROUTER_KEY}"
          baseURL: "https://openrouter.ai/api/v1"
          models:
            default:
              - "google/gemini-3.5-flash"
              - "deepseek/deepseek-v4-pro"
            fetch: true
          titleConvo: true
          titleModel: "google/gemini-2.5-flash"
          dropParams: ["stop"]
          modelDisplayLabel: "OpenRouter"
  '';
in
{
  services.podman = {
    enable = true;
    autoUpdate = {
      enable = true;
      onCalendar = "Sun *-*-* 04:00:00";
    };

    networks.librechat = { };

    containers.actual = {
      image = "docker.io/actualbudget/actual-server:latest";
      autoStart = true;
      autoUpdate = "registry";
      ports = [ "127.0.0.1:5006:5006" ];
      volumes = [ "${config.home.homeDirectory}/0selfhost/actual:/data" ];
    };

    containers.silverbullet = {
      image = "ghcr.io/silverbulletmd/silverbullet:latest";
      autoStart = true;
      autoUpdate = "registry";
      ports = [ "127.0.0.1:3000:3000" ];
      volumes = [ "${config.home.homeDirectory}/0everything/silverbullet:/space" ];
    };

    containers."librechat-mongodb" = {
      image = "docker.io/library/mongo:8";
      autoStart = true;
      network = [ "librechat" ];
      volumes = [ "${librechatDir}/mongodb:/data/db:Z" ];
      exec = "--noauth";
      extraPodmanArgs = [ "--memory=512m" ];
    };

    containers."librechat-meilisearch" = {
      image = "docker.io/getmeili/meilisearch:v1.35.1";
      autoStart = true;
      network = [ "librechat" ];
      volumes = [ "${librechatDir}/meilisearch:/meili_data:Z" ];
      environment = {
        MEILI_NO_ANALYTICS = "true";
        MEILI_MASTER_KEY = meiliMasterKey;
      };
      extraPodmanArgs = [ "--memory=512m" ];
    };

    containers."librechat-api" = {
      image = "ghcr.io/danny-avila/librechat-dev:latest";
      autoStart = true;
      autoUpdate = "registry";
      ports = [ "127.0.0.1:8080:3080" ];
      network = [ "librechat" ];
      userNS = "keep-id";
      volumes = [
        "${librechatDir}/librechat.yaml:/app/librechat.yaml:Z"
        "${librechatDir}/images:/app/client/public/images:Z"
        "${config.home.homeDirectory}/0llm:/0llm:Z"
      ];
      environment = {
        HOST = "0.0.0.0";
        PORT = "3080";
        MONGO_URI = "mongodb://librechat-mongodb:27017/LibreChat";
        MEILI_HOST = "http://librechat-meilisearch:7700";
        MEILI_MASTER_KEY = meiliMasterKey;
        SEARCH = "true";
        ALLOW_REGISTRATION = "true";
        REGISTER_MAX = "20";
        CREDS_KEY = credsKey;
        CREDS_IV = credsIv;
        JWT_SECRET = jwtSecret;
        JWT_REFRESH_SECRET = jwtRefreshSecret;
      };
      environmentFile = [ "${librechatDir}/openrouter-key" ];
    };
  };

  home.file."0selfhost/librechat/librechat.yaml".source = librechatYaml;

  home.activation.selfhostDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${config.home.homeDirectory}/0selfhost/actual
    run mkdir -p ${librechatDir}/mongodb
    run mkdir -p ${librechatDir}/meilisearch
    run mkdir -p ${librechatDir}/images
  '';
}
