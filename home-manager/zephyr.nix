{ pkgs, ... }:
{
  # Host dependencies for Zephyr RTOS development.
  # https://docs.zephyrproject.org/latest/develop/getting_started/index.html
  home.packages = with pkgs; [
    git
    cmake
    ninja
    gperf
    ccache
    dfu-util
    dtc
    wget
    (python3.withPackages (p: [ p.tkinter ]))
    xz
    file
    gnumake
    gcc
    gplusplus
    SDL2
  ];
}
