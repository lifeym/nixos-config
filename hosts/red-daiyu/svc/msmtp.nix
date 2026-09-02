{ config, pkgs, ... }:
{
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      aliases = "/etc/aliases";
    };
    accounts.default = {
      host = "smtp.qq.com";
      port = 587;
      auth = "plain";
      tls = "on";
      tls_starttls = "on";
      from = "lifeym@qq.com";
      user = "lifeym@qq.com";
      passwordeval = ''cat ${config.sops.secrets."smtp/token".path}'';
    };
  };

  environment.etc.aliases.text = ''
    root: lifeym@qq.com
  '';
}
