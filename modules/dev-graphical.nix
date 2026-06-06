{
  config,
  pkgs,
  ...
}:

let
  # Reads the Kagi API key from the GNOME Keyring at launch and exports it for
  # the Kagi MCP server, keeping the key out of the world-readable Nix store.
  # Store the key once per machine (see docs/credentials/KAGI_API_KEY.md).
  kagiMcp = pkgs.writeShellScript "kagi-mcp" ''
    set -euo pipefail
    KAGI_API_KEY="$(${pkgs.libsecret}/bin/secret-tool lookup service kagi 2>/dev/null || true)"
    if [ -z "''${KAGI_API_KEY:-}" ]; then
      echo "Kagi API key not found in the GNOME Keyring." >&2
      echo "Run: secret-tool store --label='Kagi API Key' service kagi" >&2
      exit 1
    fi
    export KAGI_API_KEY
    exec ${pkgs.uv}/bin/uvx kagimcp
  '';
in
{
  home.packages = with pkgs; [
    uv # provides uvx, which runs the Kagi MCP server
    libsecret # provides secret-tool for GNOME Keyring access
  ];

  # GUI text editor
  programs.zed-editor = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.zed-editor;
    extensions = [
      "nix"
      "rust"
      "toml"
      "catppuccin-icons"
      "git-firefly"
      "TOML"
      "Dockerfile"
      "xml"
      "make"
      "opentofu"
    ];
    userSettings = {
      agent = {
        dock = "right";
        default_model = {
          provider = "openrouter";
          model = "deepseek/deepseek-v4-flash";
        };
        use_modifier_to_send = false;
        play_sound_when_agent_done = "always";
        notify_when_agent_waiting = "primary_screen";
        thinking_display = "always_expanded";
      };
      language_models = {
        open_router = {
          api_url = "https://openrouter.ai/api/v1";
          available_models = [
            {
              name = "google/gemini-3.5-flash";
              display_name = "Gemini 3.5 Flash (Fast, Wordy)";
              max_tokens = 1000000;
              supports_tools = true;
              supports_images = true;
            }
            {
              name = "deepseek/deepseek-v4-pro";
              display_name = "DS V4 Pro (Terse, Direct)";
              max_tokens = 1000000;
              supports_tools = true;
            }
          ];
        };
      };
      agent_servers = {
        claude-acp = {
          type = "registry";
          env = {
            # Pin where the ACP agent reads settings.json, independent of
            # whatever environment GNOME hands Zed.
            CLAUDE_CONFIG_DIR = "${config.home.homeDirectory}/.claude";
          };
        };
      };
      context_servers = {
        kagi = {
          source = "custom";
          command = "${kagiMcp}";
          args = [ ];
          env = { };
        };
        git = {
          source = "custom";
          command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
          args = [ ];
          env = { };
        };
        time = {
          source = "custom";
          command = "${pkgs.mcp-server-time}/bin/mcp-server-time";
          args = [ ];
          env = { };
        };
        sequential-thinking = {
          source = "custom";
          command = "${pkgs.mcp-server-sequential-thinking}/bin/mcp-server-sequential-thinking";
          args = [ ];
          env = { };
        };
        nixos = {
          source = "custom";
          command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
          args = [ ];
          env = { };
        };
      };
      collaboration_panel = {
        dock = "left";
        button = false;
      };
      project_panel = {
        dock = "left";
        hide_hidden = false;
      };
      outline_panel = {
        dock = "left";
      };
      git_panel = {
        dock = "left";
      };
      cli_default_open_behavior = "new_window";
      extend_comment_on_newline = false;
      # Disable AI inline edit predictions and autocomplete
      edit_predictions = {
        provider = "none";
      };
      show_edit_predictions = false;
      completions = {
        words = "disabled";
      };
      show_completion_documentation = false;
      show_completions_on_input = false;
      icon_theme = "Catppuccin Frappé";
      theme = "Gruvbox Dark Hard";
      buffer_font_features = {
        calt = false;
      };
      lsp = {
        rust-analyzer = {
          initialization_options = {
            cargo = {
              features = "all";
            };
          };
        };
      };
      languages =
        let
          prettierFormatter = {
            format_on_save = "on";
            formatter = {
              external = {
                command = "prettier";
                arguments = [
                  "--stdin-filepath"
                  "{buffer_path}"
                ];
              };
            };
          };
        in
        {
          Markdown = prettierFormatter;
          JSON = prettierFormatter;
          YAML = prettierFormatter;
          CSS = prettierFormatter;
          HTML = prettierFormatter;
          JavaScript = prettierFormatter;
          TypeScript = prettierFormatter;
          TSX = prettierFormatter;
        };
    };
  };

  # Claude Code is used only through Zed's ACP agent (claude-acp above)
  programs.claude-code = {
    enable = true;
    package = null; # Don't install the CLI
    settings.permissions = {
      allow = [
        "mcp__kagi"
        "mcp__git__git_status"
        "mcp__git__git_log"
        "mcp__git__git_show"
        "mcp__git__git_diff"
        "mcp__git__git_diff_staged"
        "mcp__git__git_diff_unstaged"
        "mcp__git__git_branch"
        "mcp__time"
        "mcp__sequential-thinking"
        "mcp__nixos"
      ];
      deny = [
        "WebSearch"
        "WebFetch"
      ];
    };
  };
}
