{ config, lib, ... }:

let
  c = import ../consts.nix;
in
{
  services.ncps = {
    enable = true;
    server.addr = "[::]:8501";
    cache = {
      hostName = "cache.lifeym.xyz";
      maxSize = "300G";
      lru.schedule = "0 2 * * *";  # Daily at 2 AM
      storage.local = "${c.statePath}ncps";
      upstream = {
        urls = [
          "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
          "https://mirrors.ustc.edu.cn/nix-channels/store"
          "https://mirror.sjtu.edu.cn/nix-channels/store"
          "https://cache.nixos.org"
        ];
        publicKeys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
      };
    };
  };

  systemd.services.ncps = {
    requires = [
      "mnt-data.mount"
    ];
    after = [
      "mnt-data.mount"
    ];
  };
}
