{ config, lib, ... }:

let
  c = import ../consts.nix;
in
{
  # Woodpecker Server
  services.woodpecker-server = {
    enable = true;

    # 基礎環境配置
    environment = {
      # Server fully qualified URL of the user-facing hostname, port (if not default for HTTP/HTTPS) and path prefix.
      WOODPECKER_HOST = "https://ci.${c.mydomain}";

      # Configures the HTTP listener, supports unix socket via unix:// prefix".
      WOODPECKER_SERVER_ADDR = "${c.services.woodpecker-server.addr}:${toString c.services.woodpecker-server.port}";

      # Enable to allow user registration.
      WOODPECKER_OPEN = "true";

      # 数据库：单机首选 SQLite，数据存储在 /var/lib/woodpecker-server/
      # WOODPECKER_DATABASE_DRIVER = "sqlite3";
      WOODPECKER_DATABASE_DRIVER = "mysql";
      WOODPECKER_DATABASE_DATASOURCE_FILE = "${c.statePath}woodpecker-server/datasource";
      # WOODPECKER_DATABASE_DATASOURCE = statePath "woodpecker-server/woodpecker.sqlite";

      # 注：此处的 Client ID 和 Secret 需要在 Gitea 的「应用（OAuth2）」中生成
      WOODPECKER_GITEA = "true";
      WOODPECKER_GITEA_URL = "https://git.${c.mydomain}";
      WOODPECKER_GITEA_CLIENT = "ba299b9c-84a6-448d-8e0b-1d04eb7492f1";
      WOODPECKER_GITEA_SECRET_FILE = "${c.statePath}woodpecker-server/gitea-secret";

      # 建議將敏感密鑰放入外部文件（參見下方步驟 2）
      # WOODPECKER_GITEA_SECRET_FILE = "/run/secrets/woodpecker-gitea-secret";
      WOODPECKER_AGENT_SECRET_FILE = "${c.statePath}woodpecker-server/agent-secret";
    };
  };

  systemd.services.woodpecker-server = {
    requires = [
      "mnt-data.mount"
    ];
    after = [
      "mnt-data.mount"
    ];
  };

  #  Woodpecker Agent / Runner
  services.woodpecker-agents = {
    agents = {
      "local-runner" = {
        enable = true;
        environment = {
          WOODPECKER_SERVER = "${c.services.woodpecker-server.addr}:${toString c.services.woodpecker-server.port}"; # 連接本機 Server
          WOODPECKER_MAX_WORKERS = "4";         # 同時並發的構建任務數

          # 告訴 Runner 使用本機的 Podman/Docker 套接字來創建 CI 容器
          WOODPECKER_BACKEND = "docker";
          DOCKER_HOST = "unix:///run/podman/podman.sock";

          WOODPECKER_AGENT_SECRET_FILE = "${c.statePath}woodpecker-server/agent-secret";
        };
      };
    };
  };
}
