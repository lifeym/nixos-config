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
        listen 80;
        server_name _;
        location / {
          return 301 https://$host$request_uri;
        }
      }
    '';

    virtualHosts = lib.mapAttrs (domain: vhostCfg: {
      onlySSL = true;
      sslCertificate = "/var/lib/acme/lifeym.xyz/cert.pem";
      sslCertificateKey = "/var/lib/acme/lifeym.xyz/key.pem";
      listen = [
        { addr = "${c.roles.web}"; port = 443; ssl = true; }
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
        (listenAddrPort: cfg: ''
         server {
           listen ${listenAddrPort};
           proxy_pass ${cfg.target};
         }
        '')
        c.nginx.streams);
  };
}
