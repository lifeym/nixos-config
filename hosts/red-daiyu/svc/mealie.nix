{ config, lib, pkgs, ... }:

let
  c = import ../consts.nix;
  svc = c.services.mealie;
in
{
  virtualisation.oci-containers.containers.mealie = {
    autoStart = true;
    image = "ghcr.io/mealie-recipes/mealie:v3.24.0";
    pull = "missing";
    networks = [ "nas" ];
    # ports = [ "${toString svc.port}:80" ];   # 监听 127.0.0.1:9283
    volumes = [
      "${c.statePath}mealie/data:/app/data"
    ];
    environment = {
      PUID = "1000";
      PGID = "100";
      TZ = "Asia/Shanghai";
      ALLOW_SIGNUP = "false";
      BASE_URL = "https://meal.${c.mydomain}";
    };
    extraOptions = [
      "--ip=${svc.addr}"
    ];
  };
}
