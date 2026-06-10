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
      # Editor UI and behavior
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
          SCSS = prettierFormatter;
          HTML = prettierFormatter;
          JavaScript = prettierFormatter;
          TypeScript = prettierFormatter;
          TSX = prettierFormatter;
        };

      # AI: models, agents, MCP servers, and Zed Agent tool permissions
      # Disable AI inline edit predictions
      edit_predictions = {
        provider = "none";
      };
      show_edit_predictions = false;
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
            CLAUDE_CONFIG_DIR = "${config.home.homeDirectory}/.claude";
          };
        };
      };
      context_servers = {
        kagi = {
          command = "${kagiMcp}";
          args = [ ];
          env = { };
        };
        git = {
          command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
          args = [ ];
          env = { };
        };
        time = {
          command = "${pkgs.mcp-server-time}/bin/mcp-server-time";
          args = [ ];
          env = { };
        };
        sequential-thinking = {
          command = "${pkgs.mcp-server-sequential-thinking}/bin/mcp-server-sequential-thinking";
          args = [ ];
          env = { };
        };
        nixos = {
          command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
          args = [ ];
          env = { };
        };
      };
      agent = {
        dock = "right";
        default_model = {
          provider = "openrouter";
          model = "deepseek/deepseek-v4-flash";
          enable_thinking = true;
        };
        default_profile = "write";
        profiles = { };
        favorite_models = [
          {
            provider = "openrouter";
            model = "google/gemini-3.5-flash";
            enable_thinking = false;
          }
          {
            provider = "openrouter";
            model = "deepseek/deepseek-v4-pro";
            enable_thinking = false;
          }
          {
            provider = "openrouter";
            model = "deepseek/deepseek-v4-flash";
            enable_thinking = true;
          }
        ];
        use_modifier_to_send = false;
        play_sound_when_agent_done = "always";
        notify_when_agent_waiting = "primary_screen";
        thinking_display = "always_expanded";
        tool_permissions = {
          default = "confirm";
          tools =
            builtins.listToAttrs (
              map
                (tool: {
                  name = tool;
                  value.default = "allow";
                })
                [
                  "mcp:kagi:kagi_search_fetch"
                  "mcp:kagi:kagi_extract"
                  "mcp:git:git_status"
                  "mcp:git:git_log"
                  "mcp:git:git_show"
                  "mcp:git:git_diff"
                  "mcp:git:git_diff_staged"
                  "mcp:git:git_diff_unstaged"
                  "mcp:git:git_branch"
                  "mcp:time:get_current_time"
                  "mcp:time:convert_time"
                  "mcp:sequential-thinking:sequentialthinking"
                  "mcp:nixos:nix"
                  "mcp:nixos:nix_versions"
                ]
            )
            // {
              search_web.default = "deny";
            };
        };
      };
    };
  };

  # Claude Code, used only through the claude-acp agent above. These tool
  # permissions mirror the Zed Agent tool_permissions just above.
  programs.claude-code = {
    enable = true;
    package = null; # Don't install the CLI
    settings.permissions = {
      allow = [
        "Read(~/0config/**)"
        "Read(~/0llm/**)"
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
      ];
    };
  };

  # Shared agent instructions and skills
  home.file.".config/zed/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/0llm/AGENTS.md";
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/0llm/AGENTS.md";
  home.file.".agents/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/0llm/skills";
  home.file.".claude/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/0llm/skills";
}
