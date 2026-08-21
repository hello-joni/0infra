{ pkgs, inputs, ... }:
{
  # Host dependencies for Zephyr RTOS development.
  # https://docs.zephyrproject.org/latest/develop/getting_started/index.html
  #
  # Zephyr SDK, Python environment (includes west), and host tools are
  # provided by zephyr-nix. Uses a fork with a setuptools-scm constraint
  # fix until upstream resolves
  # https://github.com/nix-community/zephyr-nix/issues/58
  # home.packages =
  #   (with pkgs; [
  #     git
  #     cmake
  #     ninja
  #     gperf
  #     ccache
  #     dfu-util
  #     dtc
  #     wget
  #     xz
  #     file
  #     gnumake
  #     gcc
  #     SDL2
  #   ])
  #   ++ [
  #     (inputs.zephyr-nix.packages.${pkgs.system}.sdk.override {
  #       targets = [ "arm-zephyr-eabi" ];
  #     })
  #     inputs.zephyr-nix.packages.${pkgs.system}.pythonEnv
  #     inputs.zephyr-nix.packages.${pkgs.system}.hosttools-nix
  #   ];
}

# Zephyr cache:

# ```
# west config --global update.auto-cache yes
# ```
