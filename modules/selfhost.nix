{
  config,
  lib,
  ...
}:

let
  # mcpo (Open WebUI's MCP-to-OpenAPI proxy) hosts the MCP servers and exposes
  # each under its own subpath, e.g. http://mcpo:8000/filesystem. The config
  # follows the Claude Desktop format, the same shape used in dev-graphical.nix.
  # For now it runs only the filesystem server, rooted at the mounted /0llm.
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
in
{
  services.podman = {
    enable = true;
    autoUpdate = {
      enable = true;
      onCalendar = "Sun *-*-* 04:00:00";
    };

    # Shared network so Open WebUI can reach mcpo by name. Not internal, because
    # both need outbound access: Open WebUI to OpenRouter, mcpo to npm for the
    # filesystem server.
    networks.mcp = { };

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
      environment = {
        WEBUI_AUTH = "False";
      };
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
  };

  home.file."0selfhost/mcpo/config.json".source = mcpoConfig;

  home.activation.selfhostDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${config.home.homeDirectory}/0selfhost/actual
    run mkdir -p ${config.home.homeDirectory}/0selfhost/open-webui
  '';
}
