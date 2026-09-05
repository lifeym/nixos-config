{ config, lib, pkgs, ... }:

let
  c = import ../consts.nix;
  upstreamOf = name: let s = c.services.${name}; in "http://${s.addr}:${toString s.port}";
  defaultLocation = targetName: {
    proxyPass = upstreamOf targetName;
    proxyWebsockets = true;
  };
in
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    appendHttpConfig = ''
      server {
        listen ${c.roles.web.ipv4}:80 default_server;
        listen [${c.roles.web.ipv6}]:80 default_server;
        server_name _;
        location / {
          return 301 https://$host$request_uri;
        }
      }

      server {
        listen ${c.roles.web.ipv4}:443 ssl default_server;
        listen [${c.roles.web.ipv6}]:443 ssl default_server;
        server_name _;
        ssl_certificate /var/lib/acme/lifeym.xyz/cert.pem;
        ssl_certificate_key /var/lib/acme/lifeym.xyz/key.pem;
        return 444;
      }
    '';

    virtualHosts = lib.mapAttrs (domain: vhostCfg: {
      onlySSL = true;
      sslCertificate = "/var/lib/acme/lifeym.xyz/cert.pem";
      sslCertificateKey = "/var/lib/acme/lifeym.xyz/key.pem";
      listen = [
        { addr = "${c.roles.web.ipv4}"; port = 443; ssl = true; }
        { addr = "[${c.roles.web.ipv6}]"; port = 443; ssl = true; }
      ];

      # merge locations
      locations = let
        # merge locations.extraConfig
        base = { "/" = defaultLocation vhostCfg.target; };
        overrides = lib.mapAttrs (loc: locCfg:
          (defaultLocation vhostCfg.target)
          // lib.OptionalAttrs (locCfg ? extraLocationConfig) {
            extraConfig = (defaultLocation vhostCfg.target).extraConfig + "\n" + locCfg.extraLocationConfig;
          }
        ) (vhostCfg.locations or {});
      in
        base // overrides;
    }
    // lib.optionalAttrs (vhostCfg ? extraConfig) {
      extraConfig = vhostCfg.extraConfig;
    }) c.nginx.vhosts;

    streamConfig = lib.concatStringsSep "\n"
      (lib.mapAttrsToList
        (targetAddrPort: cfg: let
          listenLines = builtins.concatStringsSep "\n" (builtins.map (ip: "listen ${ip};") cfg.listen);
        in ''
         server {
           ${listenLines}
           proxy_pass ${targetAddrPort};
         }
        '')
        c.nginx.streams);
  };

  systemd.services.nginx = {
    wants = [
      "network-online.target"
    ];
    after = [
      "network-online.target"
    ];
  };
}
