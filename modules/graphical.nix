{
  config,
  pkgs,
  nixgl,
  ...
}:

{
  # Needed to wrap anything GPU-accelerated, e.g. Zed, Subsurface
  targets.genericLinux.nixGL = {
    inherit (nixgl) packages;
    defaultWrapper = "mesa";
    installScripts = [ "mesa" ];
    vulkan.enable = true;
  };

  # Consistent cursor across GTK and Qt apps on Wayland
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };

  # Qt app theming - use Adwaita Dark to match GNOME dark mode
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

  home.packages = with pkgs; [
    adwaita-qt # Adwaita theme for Qt5 apps
    adwaita-qt6 # Adwaita theme for Qt6 apps
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
              name = "deepseek/deepseek-v4-pro";
              display_name = "DS V4 Pro ($0.44/$0.87, ~58%)";
              max_tokens = 1000000;
              supports_tools = true;
            }
            {
              name = "deepseek/deepseek-v4-flash";
              display_name = "DS V4 Flash ($0.14/$0.28, ~56%)";
              max_tokens = 1000000;
              supports_tools = true;
            }
            {
              name = "google/gemini-3.5-flash";
              display_name = "Gemini 3.5 Flash ($1.50/$9, ~55%)";
              max_tokens = 1000000;
              supports_tools = true;
              supports_images = true;
            }
            {
              name = "z-ai/glm-5.1";
              display_name = "GLM-5.1 ($0.98/$3.08, 58.4%)";
              max_tokens = 203000;
              supports_tools = true;
            }
            {
              name = "moonshotai/kimi-k2.6";
              display_name = "Kimi K2.6 ($0.73/$3.49, 58.6%)";
              max_tokens = 262000;
              supports_tools = true;
            }
            {
              name = "qwen/qwen3-coder";
              display_name = "Qwen3 Coder ($0.22/$1.80, 38.7%)";
              max_tokens = 262000;
              supports_tools = true;
            }
            {
              name = "anthropic/claude-opus-4.7";
              display_name = "Claude Opus 4.7 ($5/$25, 64.3%)";
              max_tokens = 1000000;
              supports_tools = true;
              supports_images = true;
            }
            {
              name = "anthropic/claude-opus-4.6";
              display_name = "Claude Opus 4.6 ($5/$25, 53.4%)";
              max_tokens = 1000000;
              supports_tools = true;
              supports_images = true;
            }
            {
              name = "openai/gpt-5.5";
              display_name = "GPT-5.5 ($5/$30, 58.6%)";
              max_tokens = 1000000;
              supports_tools = true;
              supports_images = true;
            }
            {
              name = "openai/gpt-5.4";
              display_name = "GPT-5.4 ($2.50/$15, 57.7%)";
              max_tokens = 1000000;
              supports_tools = true;
              supports_images = true;
            }
          ];
        };
      };
      agent_servers = {
        claude-acp = {
          type = "registry";
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
      diff_view_style = "split";
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

  # GNOME Extensions
  programs.gnome-shell = {
    enable = true;
    extensions = [
      { package = pkgs.gnomeExtensions.dash-to-dock; } # Mouseover dock on the bottom of the screen
      { package = pkgs.gnomeExtensions.clipboard-indicator; } # Clipboard history
      { package = pkgs.gnomeExtensions.vitals; } # System resource usage
    ];
  };

  # Configuring GNOME
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/background" = {
        picture-uri = "file:///var/home/jhen/0everything/0media/images/backgrounds/space-background-contrast.png";
        picture-uri-dark = "file:///var/home/jhen/0everything/0media/images/backgrounds/space-background-contrast.png";
        picture-options = "zoom";
      };
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        show-battery-percentage = true;
      };
      "org/gnome/desktop/privacy" = {
        report-technical-problems = false;
      };
      "org/gnome/system/location" = {
        enabled = true;
      };
      # favorite-apps is set per-profile (personal.nix, work.nix)
      "org/gnome/shell/extensions/dash-to-dock" = {
        show-icons-notifications-counter = false;
        show-dock-urgent-notify = false;
        dock-fixed = false;
        autohide = true;
        intellihide = false;
        show-trash = false;
        show-show-apps-button = false;
      };
      "org/gnome/shell/extensions/vitals" = {
        icon-style = 1;
        show-battery = true;
        storage-path = "/var/home";
        hot-sensors = [
          "_processor_usage_"
          "_memory_usage_"
          "_storage_used_"
          "__network-rx_max__"
        ];
      };
      "org/gnome/settings-daemon/plugins/color" = {
        night-light-enabled = true;
        night-light-schedule-automatic = false;
        night-light-schedule-from = 20.0;
        night-light-schedule-to = 4.0;
      };
    };
  };

  # Configuring default GNOME applications
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Librewolf as default browser
      "text/html" = "io.gitlab.librewolf-community.desktop";
      "x-scheme-handler/http" = "io.gitlab.librewolf-community.desktop";
      "x-scheme-handler/https" = "io.gitlab.librewolf-community.desktop";
      "x-scheme-handler/about" = "io.gitlab.librewolf-community.desktop";
      "x-scheme-handler/unknown" = "io.gitlab.librewolf-community.desktop";
      "application/xhtml+xml" = "io.gitlab.librewolf-community.desktop";

      # mpv for video/audio
      "video/mp4" = "io.mpv.Mpv.desktop";
      "video/x-matroska" = "io.mpv.Mpv.desktop";
      "video/webm" = "io.mpv.Mpv.desktop";
      "audio/mpeg" = "io.mpv.Mpv.desktop";
      "audio/flac" = "io.mpv.Mpv.desktop";
      "audio/ogg" = "io.mpv.Mpv.desktop";

      # Foliate for ebooks
      "application/epub+zip" = "com.github.johnfactotum.Foliate.desktop";

      # Loupe for images
      "image/png" = "org.gnome.Loupe.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/webp" = "org.gnome.Loupe.desktop";
    };
  };

  # Generally, prefer Flatpak for isolated GUI apps, since it has some sandboxing
  services.flatpak = {
    enable = true;
    update = {
      auto.enable = true;
      onActivation = true;
    };
    packages = [
      {
        # Preferred browser (Firefox fork)
        appId = "io.gitlab.librewolf-community";
        origin = "flathub";
      }
      {
        # Keep Chromium around for the odd Firefox-incompatible website
        appId = "org.chromium.Chromium";
        origin = "flathub";
      }
      {
        # Notes app - proprietary ;_;
        appId = "md.obsidian.Obsidian";
        origin = "flathub";
      }
      {
        # Pleasant e-reader
        appId = "com.github.johnfactotum.Foliate";
        origin = "flathub";
      }
      {
        # Office suite
        appId = "org.libreoffice.LibreOffice";
        origin = "flathub";
      }
      {
        # Video player
        appId = "io.mpv.Mpv";
        origin = "flathub";
      }
      {
        # Basic image editing
        appId = "com.github.PintaProject.Pinta";
        origin = "flathub";
      }
      {
        # Companion app for Openterface Mini-KVM
        appId = "com.openterface.openterfaceQT";
        origin = "flathub";
      }
    ];
    overrides = {
      # Librewolf needs camera access for video calls
      "io.gitlab.librewolf-community".Context.devices = [ "all" ];
    };
  };
}
