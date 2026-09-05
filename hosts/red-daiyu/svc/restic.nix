{ config, pkgs, mylib, ... }:

let
  c = import ../consts.nix;
in
{
  services.restic.backups = {
    red-daiyu = {
      initialize = true;
      paths = [
        "/mnt/data"
      ];
      exclude = [
        "/mnt/data/media"
        "/mnt/data/backup/media"
        "/mnt/data/restic"
        "/mnt/data/shared"
        "/mnt/data/lib/ncps/store"
        "/mnt/data/lib/cjf"
        "/mnt/data/lib/mariadb"
      ];
      pruneOpts = [
        "--group-by host,tags"
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];
      extraBackupArgs = [
        "--skip-if-unchanged"
        "--tag system"
      ];
      timerConfig = {
        OnCalendar = "01:30";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };

      # Encryption key for repository
      passwordFile = config.sops.secrets."repo/red-daiyu/password".path;

      # Server URL
      repositoryFile = config.sops.secrets."repo/red-daiyu/path".path;
    };
  };

  # 注入restic备份依赖，确保本地备份数据拉取先进行
  systemd.services.restic-backups-red-daiyu = {
    wants = [
      "git-repo-sync.service"
      "mariadb-backup.service"
    ];
    after = [
      "git-repo-sync.service"
      "mariadb-backup.service"
    ];
  };

  # mariadb backup
  systemd.services."mariadb-backup" = mylib.systemdService.mkMariaBackup {
    containerName = "mariadb";
    databases = [ "giteadb" "sis" "woodpecker" ];
    pkgs = pkgs;
    backend = "podman";
    backupDir = "/mnt/data/backup/mariadb";
    dbUserFile = config.sops.secrets."db/mariadb/user".path;
    dbPasswordFile = config.sops.secrets."db/mariadb/password".path;
  } // {
    requires = [
      "mnt-data.mount"
    ];
    after = [
      "mnt-data.mount"
    ];
  };

  # git repo backup
  # git仓库备份用命令：git clone --mirror
  systemd.services."git-repo-sync" = {
    description = "Pre-backup Git repositories sync";
    requires = [
      "mnt-data.mount"
    ];
    after = [
      "mnt-data.mount"
    ];
    script = ''
      set -e
      GIT_DIR="/mnt/data/backup/git"

      echo "=== 开始更新所有 Git 仓库 ==="
      for repo in "$GIT_DIR"/*; do
        if [ -d "$repo/.git" ]; then
          echo "正在更新: $(basename "$repo")"
          (cd "$repo" && ${pkgs.git}/bin/git fetch --all --prune --tags --quiet) &
        fi
      done
      wait
      echo "=== 所有 Git 仓库已成功同步 ==="
    '';
    path = [ pkgs.git pkgs.bash pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      User = "root"; # 可依需求調整為你的用戶名
    };
  };
}
