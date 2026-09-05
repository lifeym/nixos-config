{ config, lib, ... }:

let
  c = import ../consts.nix;
in
{
  # navidrome
  services.navidrome = {
    enable = true;
    settings = {
      Address = c.services.navidrome.addr;
      Port = c.services.navidrome.port;
      MusicFolder = "/mnt/data/media/music";
      DataFolder = "${c.statePath}navidrome";
      ScanSchedule = "@every 30m";
      EnableInsightsCollector = false;
      Scanner.PurgeMissing = "always";
    };
  };

  systemd.services.navidrome = {
      requires = [ "mnt-data.mount" ];
      after = [ "mnt-data.mount" ];
  };
}
