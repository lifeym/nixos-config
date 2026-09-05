{ config, lib, ... }:

let
  c = import ../consts.nix;
in
{
  services.easytier = {
    enable = true;
    instances.home.configFile = "${c.statePath}easytier/home.conf";
  };

  systemd.services.easytier = {
    requires = [
      "mnt-data.mount"
    ];
    after = [
      "mnt-data.mount"
    ];
  };
}
