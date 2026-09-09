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

    # log settings
    logError = "${c.logs.nginx.httpError} warn";
    commonHttpConfig = ''
      log_format main '$remote_addr - $remote_user [$time_local] '
                      '"$request" $status $body_bytes_sent '
                      '"$http_referer" "$http_user_agent" '
                      'xff="$http_x_forwarded_for"';
      access_log ${c.logs.nginx.httpAccess} main buffer=64k flush=5s;
    '';
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

        # these two for upstream nginx
        listen ${c.roles.web.ipv4}:8443 ssl proxy_protocol default_server;
        listen [${c.roles.web.ipv6}]:8443 ssl proxy_protocol default_server;

        # and fetch real ip from upstream nginx
        set_real_ip_from 192.168.0.0/24;
        real_ip_header proxy_protocol;

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
      extraConfig = ''
        # these two for upstream nginx
        listen ${c.roles.web.ipv4}:8443 ssl proxy_protocol;
        listen [${c.roles.web.ipv6}]:8443 ssl proxy_protocol;

        # and fetch real ip from upstream nginx
        set_real_ip_from 192.168.0.0/24;
        real_ip_header proxy_protocol;
      '';

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

    streamConfig = ''
      log_format stream_log '$remote_addr [$time_local] $protocol $status $bytes_sent $bytes_received '
                            '$session_time "$upstream_addr" '
                            '"$upstream_bytes_sent" "$upstream_bytes_received"';
      access_log ${c.logs.nginx.streamAccess} stream_log buffer=64 flush=5s;
      error_log ${c.logs.nginx.streamError} warn;

      # limit stream per ip = 10
      limit_conn_zone $binary_remote_addr zone=stream_per_ip:10m;
      limit_conn stream_per_ip 10;
    '' + lib.concatStringsSep "\n"
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
