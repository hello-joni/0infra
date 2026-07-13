{
  config,
  pkgs,
  lib,
  ...
}:

let
  # The home-manager podman module hardcodes PATH without /usr/bin, where shadow-utils
  # provides newuidmap/newgidmap on Fedora Silverblue. Override with a stable-path PATH.
  rootlessPath = "PATH=/run/wrappers/bin:/run/current-system/sw/bin:/usr/bin:${config.home.homeDirectory}/.nix-profile/bin";

  # The Jira API token lives in the GNOME Keyring rather than the environment because
  # env vars are visible in /proc and the Nix store is world-readable. This wrapper
  # fetches it at each invocation. Store the token once per machine
  # (see docs/credentials/JIRA_API_TOKEN.md), then run `jira init` to generate
  # ~/.config/.jira/.config.yml.
  jiraCli = pkgs.writeShellScriptBin "jira" ''
    set -euo pipefail
    JIRA_API_TOKEN="$(${pkgs.libsecret}/bin/secret-tool lookup service jira 2>/dev/null || true)"
    if [ -z "''${JIRA_API_TOKEN:-}" ]; then
      echo "Jira API token not found in the GNOME Keyring." >&2
      echo "Run: secret-tool store --label='Jira API Token' service jira" >&2
      exit 1
    fi
    export JIRA_API_TOKEN
    exec ${pkgs.jira-cli-go}/bin/jira "$@"
  '';

  # Open WebUI chat agent — local instance on port 8180.
  # The design mirrors ~/0config/modules/selfhost.nix: Open WebUI talks to models via
  # OpenRouter, and to MCP tool servers via mcpo, all on a shared podman network.
  # Open Terminal provides a sandboxed shell with git-only access to 0notes.

  # mcpo runs each MCP server as a subprocess and exposes it over HTTP so Open WebUI
  # can register them as OpenAPI tool servers. These are the same servers that
  # dev-graphical.nix configures for Zed and Claude Code.
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
        git = {
          command = "uvx";
          args = [ "mcp-server-git" ];
        };
      };
    }
  );

  # Non-secret environment for Open WebUI. Secrets (OpenRouter key, terminal bearer key,
  # session key) are in ~/0secrets/open-webui-secret.env, hand-created and mode 600.
  defaultModelParams = builtins.toJSON { function_calling = "native"; };
  defaultModelMetadata = builtins.toJSON {
    capabilities = {
      builtin_tools = false;
    };
  };
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
    (mcpoTool "git" "Git"
      "Read and manipulate Git repositories. Use this in preference to shell git commands."
    )
  ];
  openWebuiEnv = builtins.toFile "open-webui.env" ''
    WEBUI_AUTH=False
    ENABLE_PERSISTENT_CONFIG=False
    OPENAI_API_BASE_URLS=https://openrouter.ai/api/v1
    DEFAULT_MODELS=deepseek/deepseek-v4-pro
    DEFAULT_MODEL_PARAMS=${defaultModelParams}
    DEFAULT_MODEL_METADATA=${defaultModelMetadata}
    TOOL_SERVER_CONNECTIONS=${toolServerConnections}
    ENABLE_FOLLOW_UP_GENERATION=False
  '';
in
{
  # --- Development tools ---

  home.packages = with pkgs; [
    gnumake
    go
    gopls
    vcs2l
    (python3.withPackages (ps: with ps; [ pyyaml ]))
    awscli
    podman
    podman-compose
    (pkgs.writeShellScriptBin "docker" ''
      exec podman "$@"
    '')
    pixi
    gh
    buildkite-cli
    graphviz
    jiraCli
  ];

  # --- Git and SSH identity ---

  home.file = {
    # Docker build mounts ~/.gitconfig but Home Manager writes to ~/.config/git/config
    ".gitconfig".text = ''
      [include]
        path = ~/.config/git/config
    '';

    ".config/git/config-personal".text = ''
      [user]
        name = Joni Hendrickson
        email = contact@joni.site
    '';
  };

  programs = {
    git = {
      settings.user.email = "jonathan.hendrickson@bonsairobotics.ai";
      # Personal repos on the work machine use the personal identity above.
      includes = [
        {
          condition = "gitdir:~/0config/";
          path = "~/.config/git/config-personal";
        }
        {
          condition = "gitdir:~/0notes/";
          path = "~/.config/git/config-personal";
        }
      ];
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "github.com" = {
          identityFile = "~/.ssh/work_key";
          identitiesOnly = true;
        };
        # Personal GitHub repos go through ssh.github.com with a separate key.
        "github-personal" = {
          hostname = "ssh.github.com";
          identityFile = "~/.ssh/personal_key";
          identitiesOnly = true;
        };
      };
    };
  };

  # --- Desktop environment ---

  dconf.settings."org/gnome/shell" = {
    favorite-apps = [
      "io.gitlab.librewolf-community.desktop"
      "org.gnome.Nautilus.desktop"
      "org.gnome.Ptyxis.desktop"
      "dev.zed.Zed.desktop"
      "md.obsidian.Obsidian.desktop"
      "com.logseq.Logseq.desktop"
      "com.slack.Slack.desktop"
    ];
  };

  services.flatpak.packages = [
    {
      appId = "com.logseq.Logseq";
      origin = "flathub";
    }
    {
      appId = "com.slack.Slack";
      origin = "flathub";
    }
  ];

  # --- Open WebUI chat agent (localhost:8180) ---

  services.podman = {
    enable = true;
    autoUpdate = {
      enable = true;
      onCalendar = "Sun *-*-* 04:00:00";
    };

    settings.containers.containers.label = false;

    networks.mcp = { };
    volumes."open-terminal-home" = { };

    containers."open-webui" = {
      image = "ghcr.io/open-webui/open-webui:main";
      autoStart = true;
      autoUpdate = "registry";
      ports = [ "127.0.0.1:8180:8080" ];
      network = [ "mcp" ];
      volumes = [ "${config.home.homeDirectory}/0secrets/open-webui:/app/backend/data" ];
      environmentFile = [
        "${openWebuiEnv}"
        "${config.home.homeDirectory}/0secrets/open-webui-secret.env"
      ];
      extraConfig.Service.Environment = rootlessPath;
    };

    containers.mcpo = {
      image = "ghcr.io/open-webui/mcpo:main";
      autoStart = true;
      autoUpdate = "registry";
      network = [ "mcp" ];
      environmentFile = [
        "${config.home.homeDirectory}/0secrets/mcpo-secret.env"
      ];
      # Run as container root (uid 0). Under rootless podman, container uid 0 maps to the
      # host user, so writes to the bind-mounted ~/0notes succeed. Any other container uid
      # maps to a subuid and cannot write to host-user-owned files.
      user = "0:0";
      environment = {
        # uvx caches fetched MCP servers under $HOME/.cache/uv; point it at the shared volume
        # so the cache is writable and persists across container recreates.
        HOME = "/home/user";
      };
      volumes = [
        "${config.home.homeDirectory}/0secrets/mcpo/config.json:/config.json:Z"
        "open-terminal-home.volume:/home/user"
        # The git MCP server needs filesystem access to the notes tree, which lives on the host
        # at ~/0notes and is synced via Syncthing rather than cloned inside the container.
        "${config.home.homeDirectory}/0notes:/home/user/0notes:Z"
      ];
      exec = "--host 0.0.0.0 --port 8000 --config /config.json";
      extraConfig.Service.Environment = rootlessPath;
    };

    # ~/0notes is bind-mounted so the agent's shell can read and write the synced notes tree.
    # The image runs as user `user` with home /home/user, so ~/0notes resolves to the bind mount
    # and AGENTS.md reads as written.
    containers."open-terminal" = {
      image = "ghcr.io/open-webui/open-terminal:slim";
      autoStart = true;
      autoUpdate = "registry";
      network = [ "mcp" ];
      environmentFile = [
        "${config.home.homeDirectory}/0secrets/open-terminal-secret.env"
      ];
      # The image's entrypoint drops to a non-root user, which under rootless podman maps to
      # a subuid and cannot write to ~/0notes (owned by the host user). Overriding the
      # entrypoint to skip the drop and running as container uid 0 (which maps to the host
      # user) keeps the shell able to write to the bind mount.
      # https://github.com/open-webui/open-terminal/blob/98bd1a5fd1e6d359605bca128b4048f7ffb1afe4/Dockerfile.slim#L125-L126
      user = "0:0";
      entrypoint = "/bin/sh";
      exec = "-c 'export HOME=/home/user; export PATH=/home/user/.local/bin:$PATH; mkdir -p /home/user/.local/bin; exec open-terminal run'";
      volumes = [
        "open-terminal-home.volume:/home/user"
        "${config.home.homeDirectory}/0notes:/home/user/0notes:Z"
      ];
      extraConfig.Service.Environment = rootlessPath;
    };
  };

  # The podman module's auto-update service also hardcodes PATH without /usr/bin.
  systemd.user.services."podman-auto-update".Service.Environment = rootlessPath;

  home.file."0secrets/mcpo/config.json".source = mcpoConfig;

  home.activation.secretsDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${config.home.homeDirectory}/0secrets/open-webui
  '';
}
