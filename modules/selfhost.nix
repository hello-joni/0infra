{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Open WebUI can only call tools over HTTP, and most MCP servers speak stdio instead.
  # mcpo bridges that gap by running each MCP server and exposing it as an OpenAPI endpoint
  # under its own subpath, e.g. http://mcpo:8000/filesystem. This config lists what it runs.
  mcpoConfig = builtins.toFile "mcpo-config.json" (
    builtins.toJSON {
      mcpServers = {
        filesystem = {
          command = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-filesystem"
            "/0llm"
          ];
        };
      };
    }
  );

  # Open WebUI normally stores its configuration in a database edited through the web UI.
  # Setting ENABLE_PERSISTENT_CONFIG=False makes the environment authoritative instead.
  # Secrets are stored in ~/0selfhost/open-webui-secret.env
  defaultModelParams = builtins.toJSON { function_calling = "native"; };
  defaultModelMetadata = builtins.toJSON {
    capabilities = {
      builtin_tools = false;
    };
  };
  toolServerConnections = builtins.toJSON [
    {
      type = "openapi";
      url = "http://mcpo:8000/filesystem";
      path = "openapi.json";
      auth_type = "none";
      key = "";
      config = {
        enable = true;
      };
      spec_type = "url";
      spec = "";
      info = {
        id = "filesystem";
        name = "0llm Filesystem";
        description = "Read and write files under /0llm.";
      };
    }
  ];
  openWebuiEnv = builtins.toFile "open-webui.env" ''
    WEBUI_AUTH=False
    ENABLE_PERSISTENT_CONFIG=False
    OPENAI_API_BASE_URLS=https://openrouter.ai/api/v1
    DEFAULT_MODELS=deepseek/deepseek-v4-pro
    DEFAULT_MODEL_PARAMS=${defaultModelParams}
    DEFAULT_MODEL_METADATA=${defaultModelMetadata}
    TOOL_SERVER_CONNECTIONS=${toolServerConnections}
  '';
in
{
  services.podman = {
    enable = true;
    autoUpdate = {
      enable = true;
      onCalendar = "Sun *-*-* 04:00:00";
    };

    # Shared network so Open WebUI can reach mcpo by name.
    networks.mcp = { };

    # The sandpit's own nix store, kept on a volume so its nix cache survives the
    # container being recreated rather than re-downloading every time.
    volumes."sandpit-nix" = { };

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
    containers."open-webui" = {
      image = "ghcr.io/open-webui/open-webui:main";
      autoStart = true;
      autoUpdate = "registry";
      ports = [ "127.0.0.1:8080:8080" ];
      network = [ "mcp" ];
      volumes = [ "${config.home.homeDirectory}/0selfhost/open-webui:/app/backend/data" ];
      environmentFile = [
        "${openWebuiEnv}"
        "${config.home.homeDirectory}/0selfhost/open-webui-secret.env"
      ];
    };
    containers.mcpo = {
      image = "ghcr.io/open-webui/mcpo:main";
      autoStart = true;
      autoUpdate = "registry";
      network = [ "mcp" ];
      volumes = [
        "${config.home.homeDirectory}/0selfhost/mcpo/config.json:/config.json:Z"
        "${config.home.homeDirectory}/0llm:/0llm:Z"
      ];
      exec = "--host 0.0.0.0 --port 8000 --config /config.json";
    };

    # Gives the chat agent an isolated machine with its own systemd, root
    # filesystem, and nix, so its shell never reaches the host's files or
    # credentials. This block declares only the container. nix, Open Terminal, and
    # the 0llm clone are installed inside it by a runbook, and autoUpdate stays off
    # because recreating the container would erase that installed state.
    containers."sandpit" = {
      image = "registry.access.redhat.com/ubi9/ubi-init:latest";
      autoStart = true;
      network = [ "mcp" ];
      volumes = [ "sandpit-nix.volume:/nix" ];
      extraPodmanArgs = [ "--systemd=always" ];
    };
  };

  # Open Terminal runs bare metal as a user service rather than in a container,
  # so the chat agent's shell has Joni's own host permissions and edits the real
  # ~/0llm directly with no clone or uid mapping. uvx fetches the package from
  # PyPI at runtime, which is the one non-declarative seam here. It binds 0.0.0.0
  # so the containerised Open WebUI can reach it over host.containers.internal,
  # and the API key comes from the secret file. There is no sandbox: every
  # command the model runs executes as jhen, which is the accepted trade for the
  # bare-metal shell.
  systemd.user.services.open-terminal = {
    Unit = {
      Description = "Open Terminal — bare-metal shell API for Open WebUI";
      After = [ "default.target" ];
    };
    Service = {
      ExecStart = "${pkgs.uv}/bin/uvx open-terminal run --host 0.0.0.0 --port 8000";
      EnvironmentFile = "${config.home.homeDirectory}/0selfhost/open-terminal-secret.env";
      WorkingDirectory = "${config.home.homeDirectory}";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.file."0selfhost/mcpo/config.json".source = mcpoConfig;

  home.activation.selfhostDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${config.home.homeDirectory}/0selfhost/actual
    run mkdir -p ${config.home.homeDirectory}/0selfhost/open-webui
  '';
}
