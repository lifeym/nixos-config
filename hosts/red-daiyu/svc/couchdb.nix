{ config, lib, ... }:

let
  c = import ../consts.nix;
in
{
  virtualisation.oci-containers.containers.couchdb = {
    autoStart = true;
    image = "couchdb:3";
    pull = "newer";
    networks = [ "nas" ];
    volumes = [
      "/etc/localtime:/etc/localtime:ro"
      "${c.statePath}couchdb/data:/opt/couchdb/data"
    ];
    environment = {
      COUCHDB_USER = "admin";
    };
    environmentFiles = [
      "${c.statePath}couchdb/couchdb.env"
    ];
    extraOptions = [
      "--ip=${c.services.couchdb.addr}"
    ];
  };

  systemd.services.couchdb = {
    requires = [
      "mnt-data.mount"
    ];
    after = [
      "mnt-data.mount"
    ];
  };
}
