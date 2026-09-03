# LibreChat containers as rootless podman quadlets.
# State and secrets live in ~/.local/share/librechat.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  stateDir = "${config.home.homeDirectory}/.local/share/librechat";

  # librechat.example.yaml and the custom endpoint object structure docs:
  # https://www.librechat.ai/docs/configuration/librechat_yaml/object_structure/custom_endpoint
  librechatYaml = pkgs.writeText "librechat.yaml" ''
    version: 1.3.14
    cache: true
    mcpServers:
      filesystem:
        command: npx
        args:
          - -y
          - '@modelcontextprotocol/server-filesystem'
          - /root/0llm
        # npx downloads the package on first start, so allow a long init.
        initTimeout: 60000
      # Kagi's hosted MCP. Bearer auth with the API key.
      # https://github.com/kagisearch/kagimcp
      kagi:
        type: streamable-http
        url: https://mcp.kagi.com/mcp
        headers:
          Authorization: 'Bearer ${"$"}{KAGI_API_KEY}'
        # The server answers 401 without the header, which the OAuth
        # auto-detection would misread as an OAuth requirement.
        requiresOAuth: false
    endpoints:
      custom:
        - name: OpenRouter
          apiKey: ${"$"}{OPENROUTER_API_KEY}
          baseURL: https://openrouter.ai/api/v1
          models:
            default: ['deepseek/deepseek-chat']
            fetch: true
          titleConvo: true
          titleModel: current_model
          dropParams: ['stop']
          modelDisplayLabel: OpenRouter
  '';
in
{
  services.podman = {
    enable = true;
    autoUpdate = {
      enable = true;
      onCalendar = "Sun *-*-* 04:00:00";
    };

    # Shared network so LibreChat reaches mongodb by name.
    networks.librechat = { };

    containers.librechat-mongodb = {
      image = "docker.io/library/mongo:8.0";
      autoStart = true;
      autoUpdate = "registry";
      network = [ "librechat" ];
      volumes = [ "${stateDir}/mongo:/data/db" ];
      exec = "mongod --noauth";
    };

    containers.librechat = {
      image = "ghcr.io/danny-avila/librechat:latest";
      autoStart = true;
      autoUpdate = "registry";
      network = [ "librechat" ];
      ports = [ "127.0.0.1:3080:3080" ];
      environment = {
        HOST = "0.0.0.0";
        MONGO_URI = "mongodb://librechat-mongodb:27017/LibreChat";
        ALLOW_REGISTRATION = "true";
        ALLOW_UNVERIFIED_EMAIL_LOGIN = "true";
        ALLOW_PASSWORD_RESET = "false";
        # Serves the 0llm skills as read-only deployment skills.
        DEPLOYMENT_SKILLS_DIR = "/root/0llm/skills";
      };
      environmentFile = [ "${stateDir}/librechat.env" ];
      # Container uid 0 maps to the host user, so writes to the bind mounts
      # land as joni. The image's uid 1000 maps to a subuid and cannot write.
      user = "0:0";
      volumes = [
        "${librechatYaml}:/app/librechat.yaml:ro"
        # The container runs as uid 0, whose home is /root, so the agent
        # sees the repo at ~/0llm.
        "${config.home.homeDirectory}/0llm:/root/0llm"
        "${stateDir}/images:/app/client/public/images"
        "${stateDir}/uploads:/app/uploads"
        "${stateDir}/logs:/app/logs"
        "${stateDir}/data:/app/data"
      ];
    };
  };

  # Daily restart to smooth over drift from 0llm.
  systemd.user.timers.librechat-skill-reload = {
    Timer = {
      OnCalendar = "*-*-* 02:00:00 America/Los_Angeles";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services.librechat-skill-reload = {
    ServiceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.podman}/bin/podman restart librechat";
    };
  };

  home.activation.librechatDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${stateDir}/mongo ${stateDir}/images ${stateDir}/uploads ${stateDir}/logs ${stateDir}/data
    # The LibreChat secrets don't need to be secure, since all access is
    # restricted to the tailnet. However, they're generated anyways because
    # LibreChat will not start without them.
    #
    # OPENROUTER_API_KEY and KAGI_API_KEY must be updated manually.
    if [ ! -f ${stateDir}/librechat.env ]; then
      run ${pkgs.openssl}/bin/openssl rand -hex 32 > /tmp/lc-creds-key
      run ${pkgs.openssl}/bin/openssl rand -hex 32 > /tmp/lc-creds-iv
      run ${pkgs.openssl}/bin/openssl rand -hex 32 > /tmp/lc-jwt
      run ${pkgs.openssl}/bin/openssl rand -hex 32 > /tmp/lc-jwt-refresh
      cat > ${stateDir}/librechat.env <<EOF
    CREDS_KEY=$(cat /tmp/lc-creds-key)
    CREDS_IV=$(cat /tmp/lc-creds-iv)
    JWT_SECRET=$(cat /tmp/lc-jwt)
    JWT_REFRESH_SECRET=$(cat /tmp/lc-jwt-refresh)
    OPENROUTER_API_KEY=CHANGE_ME
    KAGI_API_KEY=CHANGE_ME
    EOF
      rm -f /tmp/lc-creds-key /tmp/lc-creds-iv /tmp/lc-jwt /tmp/lc-jwt-refresh
      chmod 600 ${stateDir}/librechat.env
    fi
  '';
}
