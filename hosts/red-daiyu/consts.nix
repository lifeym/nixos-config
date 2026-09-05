# This file contains AttrSet Only.
let
  ipv6ULA = "fd33:2023:e125";
in
rec {
  roles = {
    red-daiyu = { ipv4 = "192.168.0.6"; ipv6 = "${ipv6ULA}::6"; };
    web = { ipv4 = "192.168.0.70"; ipv6 = "${ipv6ULA}::70"; };
    mariadb = { ipv4 = "192.168.0.71"; ipv6 = "${ipv6ULA}::71"; };
    cjf-mariadb = { ipv4 = "192.168.0.73"; ipv6 = "${ipv6ULA}::73"; };
  };
  # no lib.mapAttrsToList, use builtins.map instead
  networkAddress = builtins.concatMap (service: [
    "${service.ipv4}/24"
    "${service.ipv6}/64"
  ]) (builtins.attrValues roles);
  services = let
    mkLocalSvc = port: { addr = "127.0.0.1"; inherit port; };
  in {
    # container services
    mariadb = { addr = "10.33.0.3"; port = 3306; };
    cjf-mariadb = { addr = "10.33.0.4"; port = 3306; };
    gitea = { addr = "10.33.0.5"; port = 3000; };
    cwa = { addr = "10.33.0.11"; port = 8083; };
    registry-ui = { addr = "10.33.0.20"; port = 80; };
    registry-server = { addr = "10.33.0.21"; port = 5000; };
    einvault = { addr = "10.33.0.25"; port = 3000; };
    grocy = { addr = "10.33.0.26"; port = 80; };
    mealie = { addr = "10.33.0.27"; port = 9000; };

    # localhost services
    navidrome = mkLocalSvc 4533;
    woodpecker-server = mkLocalSvc 8000;
    ncps = mkLocalSvc 8501;
    transmission = mkLocalSvc 9091;
    paperless = mkLocalSvc 28981;
  };
  mydomain = "lifeym.xyz";
  nginx = {
    vhosts = {
      "aud.${mydomain}" = {
        target = "navidrome";
        extraLocationConfig = ''
          proxy_buffering on;
          proxy_buffers 8 16k;
          proxy_buffer_size 16k;
          proxy_busy_buffers_size 32k;

          proxy_read_timeout 3600s;
          proxy_send_timeout 3600s;
        '';
      };
      "bt.${mydomain}" = {
        target = "transmission";
      };
      "cache.lifeym.xyz" = {
        target = "ncps";
        extraLocationConfig = ''
          proxy_read_timeout 3600s;
          proxy_send_timeout 900s;
          proxy_connect_timeout 60s;
          proxy_buffering off;
          client_max_body_size 0;
        '';
      };
      "ci.${mydomain}" = {
        target = "woodpecker-server";
        extraConfig = "client_max_body_size 0;";
      };
      "cwa.${mydomain}" = {
        target = "cwa";
        extraLocationConfig = "client_max_body_size 100m;";
      };
      "git.${mydomain}" = {
        target = "gitea";
        extraConfig = "client_max_body_size 1G;";
      };
      "grocy.${mydomain}" = {
        target = "grocy";
        extraConfig = "client_max_body_size 100m;";
      };
      "hub.${mydomain}" = {
        target = "registry-ui";
      };
      "lcr.${mydomain}" = {
        target = "registry-server";
        extraConfig = "client_max_body_size 0;";
      };
      "meal.${mydomain}" = {
        target = "mealie";
        extraConfig = "client_max_body_size 0;";
      };
      "paperless.${mydomain}" = {
        target = "paperless";
        extraLocationConfig = "client_max_body_size 100m;";
      };
      "paw.${mydomain}" = {
        target = "einvault";
        extraConfig = ''
          client_max_body_size 0;
          proxy_buffer_size          128k;
          proxy_buffers              4 256k;
          proxy_busy_buffers_size    256k;
        ''; # can upload video?
      };
    };
    streams = { # target addr:port = listen list[]
      "${services.mariadb.addr}:${toString services.mariadb.port}" = {
        listen = [
          "${roles.mariadb.ipv4}:${toString services.mariadb.port}"
          "[${roles.mariadb.ipv6}]:${toString services.mariadb.port}"
        ];
      };
      "${services.cjf-mariadb.addr}:${toString services.cjf-mariadb.port}" = {
        listen = [
          "${roles.cjf-mariadb.ipv4}:${toString services.cjf-mariadb.port}"
          "[${roles.cjf-mariadb.ipv6}]:${toString services.cjf-mariadb.port}"
        ];
      };
      "${services.gitea.addr}:2222" = {
        listen = [
          "${roles.web.ipv4}:22"
          "[${roles.web.ipv6}]:22"
        ];
      };
    };
  };
  proxyCfg = {
    httpProxy = "http://192.168.0.6:10809";
    port = 10809;
    noProxy = "localhost,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,internal.domain,local,${mydomain},baidu.com,edu.cn";
  };

  statePath = "/mnt/data/lib/";
}
