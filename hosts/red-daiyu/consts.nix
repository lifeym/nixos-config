# This file contains AttrSet Only.
rec {
  roles = {
    red-daiyu = "192.168.0.6";
    web = "192.168.0.70";
    mariadb = "192.168.0.71";
    cjf-mariadb = "192.168.0.73";
  };
  # no lib.mapAttrsToList, use builtins.map instead
  networkAddress = builtins.map (name: (k: v:
    if k == "red-daiyu" then
      "${v}/23"
    else
      "${v}/24"
    ) name roles.${name}) (builtins.attrNames roles);
  services = let
    mkServerSvc = port: { addr = "192.168.0.6"; inherit port; };
    mkLocalSvc = port: { addr = "127.0.0.1"; inherit port; };
  in {
    # red-daiyu services
    openssh = mkServerSvc 22;
    samba = mkServerSvc null;

    # container services
    mariadb = { addr = "10.33.0.3"; port = 3306; };
    cjf-mariadb = { addr = "10.33.0.4"; port = 3306; };
    gitea = { addr = "10.33.0.5"; port = 3000; };
    cwa = { addr = "10.33.0.11"; port = 8083; };
    registry-ui = { addr = "10.33.0.20"; port = 80; };
    registry-server = { addr = "10.33.0.21"; port = 5000; };
    einvault = { addr = "10.33.0.25"; port = 3000; };

    # localhost services
    adguardhome = mkLocalSvc 3003;
    navidrome = mkLocalSvc 4533;
    woodpecker-server = mkLocalSvc 8000;
    ncps = mkLocalSvc 8501;
    mealie = mkLocalSvc 9000;
    transmission = mkLocalSvc 9091;
    grocy = mkLocalSvc 9283;
    paperless = mkLocalSvc 28981;
  };
  mydomain = "lifeym.xyz";
  nginx = let
    mkSvcTarget = svcName: let svc = services.${svcName}; in "${svc.addr}:${toString svc.port}";
  in {
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
      "dns.${mydomain}" = {
        target = "adguardhome";
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
        extraConfig = "client_max_body_size 0;"; # can upload video?
      };
    };
    streams = {
      "${roles.mariadb}:${toString services.mariadb.port}" = { target = mkSvcTarget "mariadb"; };
      "${roles.cjf-mariadb}:${toString services.cjf-mariadb.port}" = { target = mkSvcTarget "cjf-mariadb"; };
      "${roles.web}:22" = { target = "${services.gitea.addr}:2222"; };
    };
  };
  proxyCfg = {
    httpProxy = "http://192.168.0.6:10809";
    port = 10809;
    noProxy = "localhost,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,internal.domain,local,${mydomain},baidu.com,edu.cn";
  };

  statePath = "/mnt/data/lib/";
}
