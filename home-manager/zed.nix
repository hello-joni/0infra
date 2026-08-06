{
  pkgs,
  ...
}: {
  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "toml"
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

        # Syncthing folders
        "**/.stfolder"
        "**/.stversions"
      ];

      # Window and CLI behavior
      cli_default_open_behavior = "new_window";

      # Input handling
      extend_comment_on_newline = false;
      completions = {
        words = "disabled";
      };
      # TODO: These aren't for AI completions - re-enable?
      show_completion_documentation = false;
      show_completions_on_input = false;
      buffer_font_features = {
        calt = false;
      };
    };
  };
}
