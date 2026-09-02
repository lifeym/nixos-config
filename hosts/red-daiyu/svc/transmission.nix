{ config, pkgs, ... }:
{
  services.transmission = {
    enable = true;
    openFirewall = true; # 自动在系统防火墙中打开 BT 传入端口（默认 51413）

    # 核心下载设置
    settings = {
      # 1. 下载路径（注意：Transmission 默认以 transmission 用户运行，需确保该目录其有权读写）
      "download-dir" = "/mnt/downloads/bt";
      "incomplete-dir" = "/mnt/downloads/bt/.incomplete";
      "incomplete-dir-enabled" = true;

      # 2. Web 界面 (RPC) 远程控制安全设置
      "rpc-enabled" = true;
      "rpc-port" = 9091;                # Web 访问端口
      "rpc-bind-address" = "localhost";   # 允许局域网内其他设备访问
      "rpc-whitelist-enabled" = false;  # 关闭白名单（配合下一行的密码使用更方便）

      # 3. 登录 Web 界面的账号密码
      "rpc-authentication-required" = true;
      "rpc-username" = "admin";
      "rpc-password" = "password"; # 首次启动后，Samba/Transmission 会自动将其加密哈希化

      # 4. 性能与连接优化（非常适合 PT/BT 挂机）
      "peer-limit-global" = 500;
      "peer-limit-per-torrent" = 60;
      "encryption" = 1; # 优先加密连接
      "dht-enabled" = true;
      "utp-enabled" = true;
    };

    package = pkgs.transmission_4;
  };
}
