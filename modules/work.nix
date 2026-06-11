{
  pkgs,
  ...
}:

let
  # Wraps jira-cli so the Jira API token is read from the GNOME Keyring at each
  # invocation, keeping it out of the environment and the world-readable Nix
  # store. Store the token once per machine (see docs/credentials/JIRA_API_TOKEN.md),
  # then run `jira init` to generate the local ~/.config/.jira/.config.yml.
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
in
{
  home.packages = with pkgs; [
    gnumake
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
    graphviz # Visualizing `dot` graphs
    jiraCli # Jira CLI, token sourced from the GNOME Keyring
  ];

  home.file = {
    # Disable SELinux labeling for containers globally
    ".config/containers/containers.conf".text = ''
      [containers]
      label = false
    '';

    # Docker build mounts ~/.gitconfig but Home Manager writes to ~/.config/git/config
    ".gitconfig".text = ''
      [include]
        path = ~/.config/git/config
    '';

    # Use personal git identity for personal repos (0config, 0llm) on work machine
    ".config/git/config-personal".text = ''
      [user]
        name = Joni Hendrickson
        email = contact@joni.site
    '';
  };

  programs = {
    git = {
      settings.user.email = "jonathan.hendrickson@bonsairobotics.ai";
      includes = [
        {
          condition = "gitdir:~/0config/";
          path = "~/.config/git/config-personal";
        }
        {
          condition = "gitdir:~/0llm/";
          path = "~/.config/git/config-personal";
        }
      ];
    };

    # SSH alias for pushing to personal GitHub repos from work machine
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "github.com" = {
          identityFile = "~/.ssh/work_key";
          identitiesOnly = true;
        };
        "github-personal" = {
          hostname = "ssh.github.com";
          identityFile = "~/.ssh/personal_key";
          identitiesOnly = true;
        };
      };
    };
  };

  dconf.settings."org/gnome/shell" = {
    favorite-apps = [
      "io.gitlab.librewolf-community.desktop"
      "org.gnome.Nautilus.desktop"
      "org.gnome.Ptyxis.desktop"
      "dev.zed.Zed.desktop"
      "md.obsidian.Obsidian.desktop"
      "com.slack.Slack.desktop"
    ];
  };

  services.flatpak.packages = [
    {
      appId = "com.slack.Slack";
      origin = "flathub";
    }
  ];
}
