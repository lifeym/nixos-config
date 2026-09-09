{ config, lib, pkgs, ... }:

let
  c = import ../consts.nix;
in
{
  services.fail2ban = {
    enable = true;
    bantime = "2h";
    maxretry = 5;
    ignoreIP = [ "127.0.0.1/8" "192.168.0.0/23" "[::1]" "fd33:2023:e125::/48" ];

    jails = {
      sshd.settings = {
        enabled = true;
        port = "ssh";
        findtime = 600;
      };

      nginx-noscript.settings = {
        enabled = true;
        port = "http,https";
        filter = "nginx-noscript";
        logpath = "${c.logs.nginx.httpAccess}";
        findtime = 600;
        bantime = "24h";
      };

      nginx-badbots.settings = {
        enabled = true;
        port = "http,https";
        filter = "nginx-badbots";
        logpath = "${c.logs.nginx.httpAccess}";
        findtime = 600;
        bantime = "24h";
      };

      gitea-auth.settings = {
        enabled = true;
        port = "http,https";
        filter = "gitea-auth";
        logpath = "${c.logs.nginx.httpAccess}";
        maxretry = 3;
        findtime = 600;
      };

      nginx-unauthorized.settings = {
        enabled = true;
        port = "http,https";
        filter = "nginx-unauthorized";
        logpath = "${c.logs.nginx.httpAccess}";
        findtime = 600;
      };
    };
  };

  environment.etc = {
    "fail2ban/filter.d/nginx-noscript.conf".text = ''
      [Definition]
      failregex = ^<HOST> -.*"GET .*\.(php|asp|exe|pl|sh) HTTP/.*" (404|403)
    '';

    "fail2ban/filter.d/nginx-unauthorized.conf".text = ''
      [Definition]
      failregex = ^<HOST> -.*"POST .* HTTP/.*" 401
    '';

    "fail2ban/filter.d/gitea-auth.conf".text = ''
      [Definition]
      failregex = ^<HOST> -.*"POST /user/login HTTP/.*" (400|403)
    '';
  };
}
