# Distrobox: container-based development environments.
#
# Depends on the podman module, which provides the container runtime.
# Distrobox uses podman to create and manage containers that share the
# host's home directory and networking, giving you a standard distro
# environment (e.g. Ubuntu 24.04) with apt-get inside a NixOS host.
{ pkgs, ... }:
{
  imports = [ ./podman.nix ];

  environment.systemPackages = [ pkgs.distrobox ];
}
