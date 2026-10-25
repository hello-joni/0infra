# Sweet Home 3D with the MCP plugin (https://github.com/grimashevich/sweethome3d-mcp-server).
# The plugin embeds an HTTP MCP server inside the application on port 9877, so the
# server exists only while Sweet Home 3D is running. Zed connects to it as a remote
# MCP server. Imported by paolumu only.
{
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.sweethome3d.application ];

  # Sweet Home 3D scans ~/.eteks/sweethome3d/plugins/ for .sh3p files at startup.
  # The MCP repo README says ~/.sweethome3d/plugins/, but that path is wrong;
  # the official plugin guide gives the path below.
  home.file.".eteks/sweethome3d/plugins/sh3d-mcp-plugin-1.1.0.sh3p".source = pkgs.fetchurl {
    url =
      "https://github.com/grimashevich/sweethome3d-mcp-server/releases/download/v1.1.0/sh3d-mcp-plugin-1.1.0.sh3p";
    hash = "sha256-uQ4UXFagpwH1TVyeEdF0QKIkHjZOmpXZrvTwM0hfTUg=";
  };

  # Attrsets merge across modules, so this adds to the context_servers in zed.nix.
  # If Zed prompts for OAuth against this server, switch to an mcp-remote stdio
  # bridge entry instead (see https://zed.dev/docs/ai/mcp).
  programs.zed-editor.userSettings.context_servers.sweethome3d = {
    url = "http://127.0.0.1:9877/mcp";
    headers = { };
  };
}