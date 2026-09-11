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

      nginx-malicious.settings = {
        enabled = true;
        port = "http,https";
        filter = "nginx-malicious";
        logpath = "${c.logs.nginx.httpAccess}";
        findtime = 60;
        maxretry = 3;
        bantime  = 86400;
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

    "fail2ban/filter.d/nginx-malicious.conf".text = ''
      [Definition]
      failregex = ^<HOST> \- \- \[.*\] "GET \/(?:.*?)\.(?:php|asp|aspx|jsp|cgi|pl|sh|bash|py|txt|sql|env|yaml|yml|ini|conf)(?:[\s?].*)?" (?:400|404|403|444)
            ^<HOST> \- \- \[.*\] "-(?:.*)?" 400
            ^<HOST> \- \- \[.*\] ".*?(?:\x00|select|union|insert|update|delete|drop|alter|where|from|concat|md5|benchmark|sleep|and|or).*?" (?:400|403|404|444|500)
            ^<HOST> \- \- \[.*\] ".*?(?:<script|javascript:|onerror=|onload=|alert\(|document\.cookie).*?" (?:400|403|404|444)
            ^<HOST> \- \- \[.*\] ".*?(?:\.\.\/|\.\.\\|etc\/passwd|boot\.ini|win\.ini|proc\/self\/environ).*?" (?:400|403|404|444)
            ^<HOST> \- \- \[.*\] ".*?\/cgi-bin\/(?:.*?)\.(?:cgi|pl|sh|bash)(?:[\s?].*)?"
            ^<HOST> \- \- \[.*\] ".*?(?:\$\{IFS\}|wget\s|curl\s|chmod\s|chown\s|rm\s\-rf|base64|eval\(|passthru|shell_exec|system\(|phpinfo).*?" (?:400|403|404|444|500)
            ^<HOST> \- \- \[.*\] ".*?" (?:400|444)
      ignoreregex = ^<HOST> \- \- \[.*\] "GET \/favicon\.ico
                    ^<HOST> \- \- \[.*\] "GET \/robots\.txt
    '';

    "fail2ban/filter.d/gitea-auth.conf".text = ''
      [Definition]
      failregex = ^<HOST> -.*"POST /user/login HTTP/.*" (400|403)
    '';
  };
}
