{ config, lib, pkgs, ... }:

let
  c = import ../consts.nix;
  svc = c.services.einvault;
in
{
  virtualisation.oci-containers.containers.einvault = {
    autoStart = true;
    image = "ghcr.io/davefatkin/einvault:latest";
    pull = "newer";
    networks = [ "nas" ];
    volumes = [
      "${c.statePath}einvault/data:/data"
    ];
    environment = {
      PUID = "1000";
      PGID = "100";
      TZ = "Asia/Shanghai";
      ORIGIN = "https://paw.${c.mydomain}";
      NODE_ENV = "production";
      UPLOAD_MAX_MB = "10";
      VIDEO_MAX_MB = "100";
    };
    extraOptions = [
      "--ip=${svc.addr}"
    ];
  };
}
