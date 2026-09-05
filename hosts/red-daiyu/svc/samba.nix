{ config, lib, ... }:

let
  c = import ../consts.nix;
in
{
  # Samba
  # See: https://nixos.wiki/wiki/Samba
  # SeeAlso: smb.conf man (https://www.samba.org/samba/docs/current/man-html/smb.conf.5)
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "Lifeym's Home Lab Samba Server";
        "netbios name" = "smbnix";
        "security" = "user";
        "interfaces" = "${c.roles.red-daiyu.ipv4} ${c.roles.red-daiyu.ipv6}";
        "bind interfaces only" = "yes";
        "use sendfile" = "yes";
        "hosts allow" = "192.168.0. fd33:2023:e125::/48 127.0.0.1 localhost [::1]";
        "hosts deny" = "0.0.0.0/0 ::/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "passdb backend" = "tdbsam:${c.statePath}samba/private/passdb.tdb"; # TDB based password storage backend
      };
      "downloads" = {
        "path" = "/mnt/downloads";
        "browseable" = "yes";
        # "read only" = "yes";
        "guest ok" = "yes";
        # "create mask" = "0644";
        # "directory mask" = "0755";
        # "force user" = "username";
        # "force group" = "groupname";
      };
      # "private" = {
      #   "path" = "/mnt/Shares/Private";
      #   "browseable" = "yes";
      #   "read only" = "no";
      #   "guest ok" = "no";
      #   "create mask" = "0644";
      #   "directory mask" = "0755";
      #   "force user" = "username";
      #   "force group" = "groupname";
      # };
    };
  };

  # Enable Web Services Dynamic Discovery host daemon.
  # This enables (Samba) hosts, like your local NAS device,
  #   to be found by Web Service Discovery Clients like Windows.
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  systemd.services.samba = {
    requires = [
      "mnt-data.mount"
      "mnt-downloads.mount"
    ];
    after = [
      "mnt-data.mount"
      "mnt-downloads.mount"
    ];
  };
}
