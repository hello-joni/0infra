{
  pkgs,
  lib,
  ...
}: {
  # Bash stays as the login shell; fish is launched for interactive sessions.
  # Run `bash` to drop back into a real bash shell.
  programs.bash = {
    enable = true;
    initExtra = ''
      if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  programs.fish = {
    enable = true;
    generateCompletions = true;

    # Prefix the prompt with (ssh)(db)(nix) tags when the corresponding
    # context applies. Order is fixed: outer to inner.
    functions.fish_prompt = ''
      # Capture status/pipestatus first; anything below resets $status.
      set -l last_pipestatus $pipestatus
      set -lx __fish_last_status $status

      set -l shown 0
      if set -q SSH_CONNECTION
        set_color yellow
        echo -n '(ssh)'
        set_color normal
        set shown 1
      end
      if set -q CONTAINER_ID
        set_color red
        echo -n '(db)'
        set_color normal
        set shown 1
      end
      if set -q IN_NIX_SHELL
        set_color blue
        echo -n '(nix)'
        set_color normal
        set shown 1
      end
      if test $shown -eq 1
        echo -n ' '
      end

      # Inlined verbatim from fish's default prompt
      # ($__fish_data_dir/tools/web_config/sample_prompts/default.fish).
      set -l normal (set_color --reset)
      set -l color_cwd $fish_color_cwd
      set -l suffix '>'
      if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
          set color_cwd $fish_color_cwd_root
        end
        set suffix '#'
      end
      set -l bold_flag --bold
      set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
      if test $__fish_prompt_status_generation = $status_generation
        set bold_flag
      end
      set __fish_prompt_status_generation $status_generation
      set -l status_color (set_color $fish_color_status)
      set -l statusb_color (set_color $bold_flag $fish_color_status)
      set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)
      echo -n -s (prompt_login)' ' (set_color $color_cwd) (prompt_pwd) $normal (fish_vcs_prompt) $normal " "$prompt_status $suffix " "
    '';

    interactiveShellInit = ''
      fish_config theme choose base16-default
      # Show "*" for unstaged and "+" for staged changes after the git branch name.
      set -g __fish_git_prompt_showdirtystate yes
      # Make `nix develop` / `nix shell` launch fish instead of bash.
      if type -q nix-your-shell
        nix-your-shell fish | source
      end
      # Colorful man pages in less
      set -gx GROFF_NO_SGR 1
      set -gx LESS_TERMCAP_mb (set_color -o red)
      set -gx LESS_TERMCAP_md (set_color -o cyan)
      set -gx LESS_TERMCAP_me (set_color normal)
      set -gx LESS_TERMCAP_se (set_color normal)
      set -gx LESS_TERMCAP_so (set_color -b white black)
      set -gx LESS_TERMCAP_ue (set_color normal)
      set -gx LESS_TERMCAP_us (set_color -o green)
    '';
  };
}
