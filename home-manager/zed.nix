{
  pkgs,
  config,
  ...
}: let
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
    exec ${pkgs.uv}/bin/uvx --python ${pkgs.python3}/bin/python3 kagimcp
  '';
in {
  home.packages = with pkgs; [
    uv # provides uvx, which runs the Kagi MCP server
    libsecret # provides secret-tool for GNOME Keyring access
    clang-tools # provides clangd for C/C++ LSP in Zed
  ];

  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "rust"
      "toml"
      "TOML"
      "Dockerfile"
      "xml"
      "make"
      "opentofu"
      "catppuccin-icons"
      "git-firefly"
    ];
    userSettings = {
      # Theming
      icon_theme = "Catppuccin Frappé";
      theme = "Gruvbox Dark Hard";

      # Panel layout
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

      # File scanning
      file_scan_exclusions = [
        # Zed's file_scan_exclusions overrides its defaults rather than extending
        # them, so the standard entries must be re-listed here.
        "**/.git"
        "**/.svn"
        "**/.hg"
        "**/.jj"
        "**/CVS"
        "**/.DS_Store"
        "**/Thumbs.db"
        "**/.classpath"
        "**/.settings"

        # Syncthing
        "**/.stfolder" # Syncthing
        "**/.stversions" # Syncthing
      ];

      # Window and CLI behavior
      cli_default_open_behavior = "new_window";

      # Input handling
      extend_comment_on_newline = false;
      # TODO: These aren't for AI completions - re-enable?
      completions = {
        words = "disabled";
      };
      show_completion_documentation = false;
      show_completions_on_input = false;
      # Disable AI inline edit predictions
      edit_predictions = {
        provider = "none";
      };
      show_edit_predictions = false;
      # Disable combining characters
      buffer_font_features = {
        calt = false;
      };

      # Language formatting
      # Prettier runs as an external formatter on save for the languages below.
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

      # LSP configuration
      lsp = {
        rust-analyzer = {
          initialization_options = {
            cargo = {
              features = "all";
            };
          };
        };
      };

      # MCP context servers
      context_servers = {
        kagi = {
          command = "${kagiMcp}";
          args = [];
          env = {};
        };
        git = {
          command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
          args = [];
          env = {};
        };
        time = {
          command = "${pkgs.mcp-server-time}/bin/mcp-server-time";
          args = [];
          env = {};
        };
      };

      # Agent configuration
      agent = {
        # UI and behavior
        dock = "right";
        use_modifier_to_send = false;
        play_sound_when_agent_done = "always";
        notify_when_agent_waiting = "primary_screen";
        thinking_display = "always_expanded";

        # Tool profiles
        profiles = {
          "0tools-standard" = {
            name = "0tools-standard";
            tools = {
              read_file = true;
              grep = true;
              find_path = true;
              list_directory = true;
              diagnostics = true;
              fetch = false;
              search_web = false;
              edit_file = true;
              write_file = true;
              copy_path = true;
              create_directory = true;
              delete_path = true;
              move_path = true;
              terminal = true;
              skill = true;
              spawn_agent = false;
            };
            enable_all_context_servers = true;
          };
          "0tools-subagents" = {
            name = "0tools-subagents";
            tools = {
              read_file = true;
              grep = true;
              find_path = true;
              list_directory = true;
              diagnostics = true;
              fetch = false;
              search_web = false;
              edit_file = true;
              write_file = true;
              copy_path = true;
              create_directory = true;
              delete_path = true;
              move_path = true;
              terminal = true;
              skill = true;
              spawn_agent = true;
            };
            enable_all_context_servers = true;
          };
        };

        # Tool permissions
        tool_permissions = {
          default = "allow";
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
              ]
            )
            // {
              search_web.default = "deny";
              terminal.default = "confirm";
            };
        };
      };
    };
  };

  # Shared agent instructions and skills
  home.file.".config/zed/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/0notes/AGENTS.md";
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/0notes/AGENTS.md";
  home.file.".agents/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/0notes/skills";
  home.file.".claude/skills".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/0notes/skills";
}
