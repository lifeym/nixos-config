{
  virtualisation.docker = {
    enable = false;
    rootless = {
      enable = true;
      setSocketVariable = true;
      daemon.settings = {
        experimental = true;
        features = {
          # The "classic" image store of the Docker Engine does not support multi-platform images.
          # Switching to the containerd image store ensures that your Docker Engine can push, pull, and build multi-platform images.
          # See: https://docs.docker.com/build/building/multi-platform/#prerequisites
          containerd-snapshotter = true;
        };
      };
    };
  };
}
