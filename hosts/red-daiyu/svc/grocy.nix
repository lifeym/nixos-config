{
}:

let
  c = import ../consts.nix;
  svc = c.services.grocy;
in
{
  virtualisation.oci-containers.containers.grocy = {
    autoStart = true;
    image = "lscr.io/linuxserver/grocy:latest";
    pull = "newer";
    networks = [ "nas" ];
    # ports = [ "${toString svc.port}:80" ];   # 监听 127.0.0.1:9283
    volumes = [
      "${c.statePath}grocy/config:/config"
    ];
    environment = {
      PUID = "1000";
      PGID = "100";
      TZ = "Asia/Shanghai";
    };
    extraOptions = [
      "--ip=${svc.addr}"
    ];
  };
}
