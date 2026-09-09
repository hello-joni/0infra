# Podman container runtime, rootless, with Docker CLI compatibility.
{
  virtualisation.podman = {
    enable = true;

    # Docker-compatible socket and API, for tools that expect Docker.
    dockerSocket.enable = true;
    dockerCompat = true;

    # Clean up dangling images and containers weekly.
    autoPrune.enable = true;
  };
}
