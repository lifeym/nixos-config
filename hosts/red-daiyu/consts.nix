# This file contains AttrSet Only.
rec {
  serverAddr = {
    red-daiyu = "192.168.0.6";
    web = "192.168.0.70";
    mariadb = "192.168.0.71";
    cjf-mariadb = "192.168.0.73";
  };
  containerAddr = {
    mariadb = "10.33.0.3";
    cjf-mariadb = "10.33.0.4";
    gitea = "10.33.0.5";
    cwa = "10.33.0.11";
    registry-ui = "10.33.0.20";
    registry-server = "10.33.0.21";
  };
  localPorts = {
    woodpecker = 8000;
    xray = 10809;
  };
  mydomain = "lifeym.xyz";
  proxyCfg = {
    httpProxy = "${serverAddr.red-daiyu}:${toString localPorts.xray}";
    port = localPorts.xray;
    noProxy = "localhost,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,internal.domain,local,${mydomain},baidu.com,edu.cn";
  };

  statePath = "/mnt/data/lib/";
}
