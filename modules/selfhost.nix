{
  config,
  lib,
  ...
}:

let
  # Open WebUI can only call tools over HTTP, and most MCP servers speak stdio instead.
  # mcpo bridges that gap by running each MCP server and exposing it as an OpenAPI endpoint
  # under its own subpath, e.g. http://mcpo:8000/kagi. This config lists what it runs.
  # These mirror the tool MCP servers configured for Zed and Claude Code in dev-graphical.nix.
  # File and shell access is not an MCP server here: it is the agent's shell through the Open
  # Terminal container, which supersedes the earlier filesystem MCP. The mcpo image bundles
  # node and uv, so the servers are fetched at runtime by uvx. The kagi server reads
  # KAGI_API_KEY from the container environment (see the mcpo container's environmentFile),
  # which keeps the key out of this world-readable config and the nix store.
  mcpoConfig = builtins.toFile "mcpo-config.json" (
    builtins.toJSON {
      mcpServers = {
        kagi = {
          command = "uvx";
          args = [ "kagimcp" ];
        };
        nixos = {
          command = "uvx";
          args = [ "mcp-nixos" ];
        };
        time = {
          command = "uvx";
          args = [
            "mcp-server-time"
            "--local-timezone=America/Los_Angeles"
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
  # Registers each mcpo subpath as an OpenAPI tool server in Open WebUI. mcpo needs no auth, so
  # the key is empty and auth_type is none. id must match the mcpo subpath (the mcpServers key).
  mcpoTool = id: name: description: {
    type = "openapi";
    url = "http://mcpo:8000/${id}";
    path = "openapi.json";
    auth_type = "none";
    key = "";
    config = {
      enable = true;
    };
    spec_type = "url";
    spec = "";
    info = { inherit id name description; };
  };
  toolServerConnections = builtins.toJSON [
    (mcpoTool "kagi" "Kagi Search" "Web search and full-page content extraction via Kagi.")
    (mcpoTool "nixos" "NixOS" "Search nixpkgs packages and NixOS, Home Manager, and Darwin options.")
    (mcpoTool "time" "Time" "Current time and timezone conversion.")
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

    # The Open Terminal home directory, kept on a volume so the 0llm clone and the agent's git
    # config survive the container being recreated or auto-updated.
    volumes."open-terminal-home" = { };

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
      # Holds KAGI_API_KEY for the kagi server. Hand-created and untracked, so it stays out of the
      # public store. mcpo merges its own environment into each MCP subprocess, so the kagi server
      # inherits the key without it appearing in config.json. See docs/credentials/KAGI_API_KEY.md.
      environmentFile = [
        "${config.home.homeDirectory}/0selfhost/mcpo-secret.env"
      ];
      volumes = [
        "${config.home.homeDirectory}/0selfhost/mcpo/config.json:/config.json:Z"
      ];
      exec = "--host 0.0.0.0 --port 8000 --config /config.json";
    };

    # Open Terminal is Open WebUI's first-party code-execution integration: the agent's shell,
    # confined to this container. Open WebUI reaches it over the shared mcp network at
    # http://open-terminal:8000 (declared in TERMINAL_SERVER_CONNECTIONS in the Open WebUI secret
    # file, since that value embeds the bearer key) and proxies it server-side, so the terminal
    # publishes no host port. The :slim image is the smallest non-Alpine (glibc) variant, carrying
    # git, curl, and jq; it cannot install packages at runtime, which is accepted.
    #
    # 0llm is a git clone on the open-terminal-home volume at /home/user/0llm, not a host mount.
    # The image runs as user `user` with home /home/user, so ~/0llm resolves to that clone and
    # AGENTS.md reads as written. The clone and the git credential helper are provisioned once by a
    # runbook; OPEN_TERMINAL_API_KEY and the scoped GitHub token come from the secret env file.
    #
    # OPEN_TERMINAL_ALLOWED_DOMAINS is the built-in egress firewall. The shell needs outbound
    # access only to GitHub for git; OpenRouter is reached by Open WebUI and the MCP tools by mcpo,
    # so locking egress to github bounds what a prompt-injected agent can reach.
    containers."open-terminal" = {
      image = "ghcr.io/open-webui/open-terminal:slim";
      autoStart = true;
      autoUpdate = "registry";
      network = [ "mcp" ];
      environment.OPEN_TERMINAL_ALLOWED_DOMAINS = "github.com,codeload.github.com";
      environmentFile = [
        "${config.home.homeDirectory}/0selfhost/open-terminal-secret.env"
      ];
      volumes = [ "open-terminal-home.volume:/home/user" ];
    };
  };

  home.file."0selfhost/mcpo/config.json".source = mcpoConfig;

  home.activation.selfhostDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${config.home.homeDirectory}/0selfhost/actual
    run mkdir -p ${config.home.homeDirectory}/0selfhost/open-webui
  '';
}
