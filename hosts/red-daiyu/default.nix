# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  mylib,
  pkgs,
  pkgs-stable,
  pkgs-unstable,
  hostName,
  ...
}:
let
  serverAddr = {
    red-daiyu = "192.168.0.6";
    web = "192.168.0.70";
    mariadb = "192.168.0.71";
    cjf-mariadb = "192.168.0.73";
  };
  localAddr = {
    mariadb = "10.33.0.3";
    cjf-mariadb = "10.33.0.4";
    gitea = "10.33.0.5";
    cwa = "10.33.0.11";
    # woodpecker = "10.33.0.15";
    registry-ui = "10.33.0.20";
    registry-server = "10.33.0.21";
  };
  proxyCfg = {
    httpProxy = "${serverAddr.red-daiyu}:10809";
    port = 10809;
    noProxy = "localhost,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,internal.domain,local,baidu.com,edu.cn";
  };

  statePath = rel: "/mnt/data/lib/${rel}";
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Enable OpenGL
  # See: https://wiki.nixos.org/wiki/AMD_GPU
  # See: https://wiki.nixos.org/wiki/Graphics#OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  boot.initrd.kernelModules = [
    "dm-snapshot"
    "dm-cache-default" # when using volumes set up with lvmcache
  ];

  # load tcp_bbr module for enabling bbr in sysctl.
  boot.kernelModules = [ "tcp_bbr" ];

  # Nested virtualization for kvm
  boot.extraModprobeConfig = "options kvm_amd nested=1";

  # Enable libvirt daemon
  # See: https://nixos.wiki/wiki/Libvirt
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_full;
      runAsRoot = true;
      swtpm.enable = true;
      verbatimConfig = ''
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm",
          "/dev/dri/renderD128"
        ]
      '';
    };
  };

  boot.kernel.sysctl = {
    # using bbr
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # File systems

  # mdadm raid
  # Or use environment.etc."mdadm.conf" instead.
  boot.swraid = {
    enable = true;
    mdadmConf = ''
    ARRAY /dev/md/openSUSE:1 metadata=1.2 UUID=890c5d74:2a8b8f7f:01c80f44:f4ed2786
    '';
  };

  services.lvm.boot.thin.enable = true; # when using thin provisioning or caching

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/9734a151-32f3-4986-ba99-d560d4bb572b";
    fsType = "xfs";
  };

  fileSystems."/mnt/store" = {
    device = "/dev/disk/by-uuid/420525b9-5ad6-4844-9dfd-e7d9cef05462";
    fsType = "xfs";
  };

  fileSystems."/mnt/downloads" = {
    device = "/dev/disk/by-uuid/bee914aa-99e5-4329-9e62-dfc26f7f0e85";
    fsType = "xfs";
  };

  fileSystems."/mnt/fast" = {
    device = "/dev/disk/by-uuid/2ae126bf-962e-4a4c-b292-f60e65e9eec5";
    fsType = "ext4";
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    inherit hostName;

    # Configure network proxy if necessary
    proxy.default = proxyCfg.httpProxy;
    proxy.noProxy = proxyCfg.noProxy; #"localhost,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,internal.domain,local,baidu.com,edu.cn";
  };

  # Use systemd-networkd to manage networks static settings.
  networking.useDHCP = false; # hardware-configuration.nix enabled this, disable it! then we can use systemd-network.
  systemd.network = {
    enable = true;
    netdevs = {
       # Create the bridge interface
       "20-br0" = {
         netdevConfig = {
           Kind = "bridge";
           Name = "br0";
         };
       };
    };

    networks = {
      "20-dhcp-br0" = {
        matchConfig.Name = "br0";
        address = [
          "${serverAddr.red-daiyu}/23"
          "${serverAddr.web}/24" # web
          "${serverAddr.mariadb}/24" # mysql
          "${serverAddr.cjf-mariadb}/24" # mysql
        ];
        dns = [
          "192.168.0.1"
          # "114.114.114.114"
        ];
        # networkConfig = {
        #   DHCP = "yes";
        # };
        routes = [
          { Gateway = "192.168.0.1"; }
        ];
      };

      # Connect the bridge ports to the bridge
      "30-enp11s0" = {
        matchConfig.Name = "enp11s0";
        networkConfig.Bridge = "br0";
        linkConfig.RequiredForOnline = "enslaved";
      };

      # Configure the bridge for its desired function
      "40-br0" = {
        matchConfig.Name = "br0";
        bridgeConfig = {};
        linkConfig = {
          # or "routable" with IP addresses configured
          # RequiredForOnline = "carrier";
          RequiredForOnline = "routable";
        };
      };
    };
  };

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.defaultUserShell = pkgs.zsh;
  users = {
    users.lifeym = {
      extraGroups = [
        "wheel" # Enable ‘sudo’ for the user.
        "libvirtd" # So this user can be used for connecting libvirt
        "podman"
      ];

      # To keep user service to stay running after a user logs out.
      # See: https://wiki.nixos.org/wiki/Systemd/User_Services
      linger = true;
      packages = with pkgs; [];
    };

    users.minidlna = {
      extraGroups = [ "users" ]; # So minidlna can access the files.
    };
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "/home/lifeym/.config/sops/age/keys.txt";
    secrets = {
      "repo/red-daiyu/password" = {};
      "repo/red-daiyu/path" = {};
      "db/mariadb/user" = {};
      "db/mariadb/password" = {};
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # utilities
    age
    bat
    chezmoi
    clipboard-jh
    dig # debug dns
    dua
    fzf
    gh
    git
    gnumake
    go-task
    htop
    neovim
    nmap # debug network
    nushell
    restic # backup tool
    ripgrep
    shellcheck
    sops # secrets management tool, can be used with restic to automate backup operation.
    starship
    tmux
    vifm
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget # curl sometimes failed to download files, wget come to help.
    zoxide

    # develop tools
    direnv
    difftastic
    git-credential-manager
    gitui

  ] ++ (with pkgs-unstable; [
    v2ray
  ]);

  environment.variables = {
    EDITOR = "vim";

    # goproxy
    GO111MODULE = "on";
    GOPROXY = "https://goproxy.cn,direct";

    VIFM = "$HOME/.config/vifm";
    XDG_CONFIG_HOME = "$HOME/.config";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  programs.zsh.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = true; # Open the firewall for SSH connections.
    listenAddresses = [
      { addr = serverAddr.red-daiyu; }
    ];
    settings = {
      PermitRootLogin = "no"; # Disable root login via SSH.
      PasswordAuthentication = false; # Disable password authentication.
      UseDns = true;
    };
  };

  # navidrome
  services.navidrome = {
    enable = true;
    settings = {
      Address = "localhost";
      Port = 4533;
      MusicFolder = "/mnt/data/media/music";
      DataFolder = "/mnt/data/lib/navidrome";
      ScanSchedule = "@every 30m";
      EnableInsightsCollector = false;
      Scanner.PurgeMissing = "always";
    };
  };

  # Samba
  # See: https://nixos.wiki/wiki/Samba
  # SeeAlso: smb.conf man (https://www.samba.org/samba/docs/current/man-html/smb.conf.5)
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "Lifeym's Home Lab Samba Server";
        "netbios name" = "smbnix";
        "security" = "user";
        "use sendfile" = "yes";
        "hosts allow" = "192.168.0. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
        "guest account" = "nobody";
        "map to guest" = "bad user";
        "passdb backend" = "tdbsam:/mnt/data/lib/samba/private/passdb.tdb"; # TDB based password storage backend
      };
      "downloads" = {
        "path" = "/mnt/downloads";
        "browseable" = "yes";
        "read only" = "yes";
        "guest ok" = "yes";
        # "create mask" = "0644";
        # "directory mask" = "0755";
        # "force user" = "username";
        # "force group" = "groupname";
      };
      # "private" = {
      #   "path" = "/mnt/Shares/Private";
      #   "browseable" = "yes";
      #   "read only" = "no";
      #   "guest ok" = "no";
      #   "create mask" = "0644";
      #   "directory mask" = "0755";
      #   "force user" = "username";
      #   "force group" = "groupname";
      # };
    };
  };

  # Enable Web Services Dynamic Discovery host daemon.
  # This enables (Samba) hosts, like your local NAS device,
  #   to be found by Web Service Discovery Clients like Windows.
  services.samba-wsdd = {
    enable = true;
    openFirewall = true;
  };

  services.minidlna = {
    enable = true;
    settings = {
      friendly_name = "red-daiyu";
      inotify = "yes"; # enable inotify monitoring to automatically discover new files.
      log_level = "error"; # reduce disk io and usage.
      media_dir = [
        "V,/mnt/store/media"
        "V,/mnt/downloads"
      ];
    };
    openFirewall = true;
  };

  # Woodpecker Server
  services.woodpecker-server = {
    enable = true;

    # 基礎環境配置
    environment = {
      # Server fully qualified URL of the user-facing hostname, port (if not default for HTTP/HTTPS) and path prefix.
      WOODPECKER_HOST = "https://ci.lifeym.xyz";

      # Configures the HTTP listener, supports unix socket via unix:// prefix".
      WOODPECKER_SERVER_ADDR = ":8000";

      # Enable to allow user registration.
      WOODPECKER_OPEN = "true";

      # 数据库：单机首选 SQLite，数据存储在 /var/lib/woodpecker-server/
      # WOODPECKER_DATABASE_DRIVER = "sqlite3";
      WOODPECKER_DATABASE_DRIVER = "mysql";
      WOODPECKER_DATABASE_DATASOURCE_FILE = statePath "woodpecker-server/datasource";
      # WOODPECKER_DATABASE_DATASOURCE = statePath "woodpecker-server/woodpecker.sqlite";

      # 注：此处的 Client ID 和 Secret 需要在 Gitea 的「应用（OAuth2）」中生成
      WOODPECKER_GITEA = "true";
      WOODPECKER_GITEA_URL = "https://git.lifeym.xyz";
      WOODPECKER_GITEA_CLIENT = "ba299b9c-84a6-448d-8e0b-1d04eb7492f1";
      WOODPECKER_GITEA_SECRET_FILE = statePath "woodpecker-server/gitea-secret";

      # 建議將敏感密鑰放入外部文件（參見下方步驟 2）
      # WOODPECKER_GITEA_SECRET_FILE = "/run/secrets/woodpecker-gitea-secret";
      WOODPECKER_AGENT_SECRET_FILE = statePath "woodpecker-server/agent-secret";
    };
  };

  #  Woodpecker Agent / Runner
  services.woodpecker-agents = {
    agents = {
      "local-runner" = {
        enable = true;
        environment = {
          WOODPECKER_SERVER = "localhost:8000"; # 連接本機 Server
          WOODPECKER_MAX_WORKERS = "4";         # 同時並發的構建任務數

          # 告訴 Runner 使用本機的 Podman/Docker 套接字來創建 CI 容器
          WOODPECKER_BACKEND = "docker";
          DOCKER_HOST = "unix:///run/podman/podman.sock";

          WOODPECKER_AGENT_SECRET_FILE = statePath "woodpecker-server/agent-secret";
        };
      };
    };
  };

  # services.easytier = {
  #   enable = true;
  #   instances.home.configFile = "/mnt/data/lib/easytier/home.conf";
  # };

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

  services.nginx = let
    sslServer = { serverName, extraConfig ? "", proxyPassAddr }: ''
      server {
        listen ${serverAddr.web}:443 ssl ;
        server_name ${serverName} ;
        ssl_certificate_key /var/lib/acme/lifeym.xyz/key.pem;
        ssl_certificate /var/lib/acme/lifeym.xyz/cert.pem;
        location / {
          ${extraConfig}
          proxy_pass http://${proxyPassAddr};
        }
        if ($server_name != $host) {
          return 301 https://$server_name$request_uri;
        }
      }
    '';

    giteaServer = sslServer {
      serverName = "git.lifeym.xyz";
      extraConfig = "client_max_body_size 1G;";
      proxyPassAddr = "${localAddr.gitea}:3000";
    };

    woodpeckerServer = sslServer {
      serverName = "ci.lifeym.xyz";
      proxyPassAddr = "localhost:8000";
    };

    dockerRegistryServer = sslServer {
      serverName = "hub.lifeym.xyz";
      proxyPassAddr = "${localAddr.registry-ui}:80";
    };

    cwaServer = sslServer {
      serverName = "cwa.lifeym.xyz";
      proxyPassAddr = "${localAddr.cwa}:8083";
    };

    nixServeServer = sslServer {
      serverName = "cache.lifeym.xyz";
      proxyPassAddr = "${config.services.ncps.server.addr}";
    };

    navidromeServer = sslServer {
      serverName = "aud.lifeym.xyz";
      proxyPassAddr = "${config.services.navidrome.settings.Address}:${toString config.services.navidrome.settings.Port}";
    };
  in {
    enable = true;
    recommendedProxySettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    appendHttpConfig = ''
      server {
        listen 80;
        server_name _;
        location / {
          return 301 https://$host$request_uri;
        }
      }

      ${giteaServer}

      ${woodpeckerServer}

      ${dockerRegistryServer}

      ${cwaServer}

      ${nixServeServer}

      ${navidromeServer}
    '';

    streamConfig = ''
      # mariadb
      server {
        listen ${serverAddr.mariadb}:3306;
        proxy_pass ${localAddr.mariadb}:3306;
      }

      # cjf-mariadb
      server {
        listen ${serverAddr.cjf-mariadb}:3306;
        proxy_pass ${localAddr.cjf-mariadb}:3306;
      }

      # gitea
      server {
        listen ${serverAddr.web}:22;
        proxy_pass ${localAddr.gitea}:2222;
      }
    '';
  };

  services.ncps = {
    enable = true;
    server.addr = "localhost:8501";
    cache = {
      hostName = "cache.lifeym.xyz";
      maxSize = "300G";
      lru.schedule = "0 2 * * *";  # Daily at 2 AM
      storage.local = "/mnt/data/lib/ncps";
      upstream = {
        urls = [
          "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
          "https://mirrors.ustc.edu.cn/nix-channels/store"
          "https://mirror.sjtu.edu.cn/nix-channels/store"
          "https://cache.nixos.org"
        ];
        publicKeys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
      };
    };
  };

  services.fail2ban = {
    enable = true;
    bantime = "1h";
    maxretry = 5;
    ignoreIP = [ "127.0.0.1/8" "192.168.0.0/23" ];

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
        logpath = "/var/log/nginx/access.log";
        findtime = 600;
      };

      nginx-badbots.settings = {
        enabled = true;
        port = "http,https";
        filter = "nginx-badbots";
        logpath = "/var/log/nginx/access.log";
        findtime = 600;
      };

      gitea-auth.settings = {
        enabled = true;
        port = "http,https";
        filter = "gitea-auth";
        logpath = "/var/log/nginx/access.log";
        maxretry = 3;
        findtime = 600;
      };

      web-unauthorized.settings = {
        enabled = true;
        port = "http,https";
        filter = "nginx-unauthorized";
        logpath = "/var/log/nginx/access.log";
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

  # Let's Encrypt certificates
  # DNS Validation for tencent cloud dns
  # See: https://go-acme.github.io/lego/dns/tencentcloud/index.html
  security.acme = {
    acceptTerms = true;
    defaults.email = "i@lifeym.xyz";
    certs."lifeym.xyz" = {
      domain = "*.lifeym.xyz";
      dnsProvider = "tencentcloud";
      environmentFile = statePath "acme/tencent";
      group = config.services.nginx.group;
    };
  };

  # Open ports in the firewall.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      80
      443
      3306 # mysql
      11010 # easytier
      proxyCfg.port # v2ray
    ] ++ lib.range 5900 5920; # Reserve5900~5920 for vnc ports
    # allowedUDPPorts = [ ... ];
  };

  # xray systemd service
  systemd.services.xray = {
    description = "Xray service";
    path = [ pkgs-unstable.xray ];
    requires = [
      "network.target" # Thanks to the systemd-networkd, or v2ray cannot auto start with network.target
      "network-online.target" # Thanks to the systemd-networkd, or v2ray cannot auto start with network.target
      "mnt-data.mount"
    ];
    after = [
      "network.target"
      "network-online.target"
      "mnt-data.mount"
    ];
    script = "xray run -c /mnt/data/lib/v2fly/config.json";
    wantedBy = [ "multi-user.target" ]; # starting a unit by default at boot time
  };

  # Use custom network to isolate nas apps from normal containers.
  # Containers not in network:my-nas cannot access them.
  systemd.services."create-nas-network" = {
    description = "Create custom network for OCI containers";
    serviceConfig.Type = "oneshot";
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.podman}/bin/podman network exists nas || \
      ${pkgs.podman}/bin/podman network create nas --subnet=10.33.0.0/24 --gateway=10.33.0.1
    '';
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
  };

  # systemd.timers."mariadb-backup" = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     OnCalendar = "00:15";
  #     Persistent = true;
  #   };
  # };

  # git repo backup
  # git仓库备份用命令：git clone --mirror
  systemd.services."git-repo-sync" = {
    description = "Pre-backup Git repositories sync";
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

  # 注入restic备份依赖，确保本地备份数据拉取先进行
  systemd.services."restic-backups-red-daiyu" = {
    wants = [
      "git-repo-sync.service"
      "mariadb-backup.service"
    ];
    after = [
      "git-repo-sync.service"
      "mariadb-backup.service"
    ];
  };

  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers = {
    # service name: {backend}-{container_name}
    calibre-web-automated = {
      image = "crocodilestick/calibre-web-automated:v4.0.6";
      autoStart = true;
      networks = [ "nas" ];
      environment = {
        PUID = "1000";
        PGID = "100";
        TZ = "Asia/Shanghai";
      };
      volumes = [
        # "/etc/localtime:/etc/localtime:ro"
        "${statePath "cwa/config"}:/config"
        "${statePath "cwa/ingest"}:/cwa-book-ingest"
        "/mnt/data/calibre-library:/calibre-library"
      ];
      extraOptions = [
        "--ip=${localAddr.cwa}"
      ];
    };

    mariadb = {
      image = "mariadb:12";
      autoStart = true;
      networks = [ "nas" ];
      environmentFiles = [
        # Sample:
        # MARIADB_ROOT_PASSWORD=YourInitPassword
        (statePath "mariadb/env")
      ];
      volumes = [ # /path/on/host:/path/inside/container
        "/etc/localtime:/etc/localtime:ro"
        "${statePath "mariadb/mysql"}:/var/lib/mysql"
        "${statePath "mariadb/conf.d"}:/etc/mysql/conf.d:ro"
      ];
      extraOptions = [
        "--ip=${localAddr.mariadb}"
      ];
    };

    "cjf-mariadb" = {
      image = "mariadb:12";
      autoStart = true;
      networks = [ "nas" ];
      environmentFiles = [
        # Sample:
        # MARIADB_ROOT_PASSWORD=YourPassword
        (statePath "cjf/mariadb/env")
      ];
      volumes = [ # /path/on/host:/path/inside/container
        "/etc/localtime:/etc/localtime:ro"
        "${statePath "cjf/mariadb/mysql"}:/var/lib/mysql"
        "${statePath "cjf/mariadb/conf.d"}:/etc/mysql/conf.d:ro"
      ];
      extraOptions = [
        "--ip=${localAddr.cjf-mariadb}"
      ];
    };

    gitea = {
      image = "docker.gitea.com/gitea:1.27-rootless";
      dependsOn = [ "mariadb" ];
      autoStart = true;
      networks = [ "nas" ];
      environment = {
        USER_UID = "1000";
        USER_GID = "1000";
        GITEA__database__DB_TYPE = "mysql";
        GITEA__database__HOST = "mariadb:3306";
      };
      environmentFiles = [
        (statePath "gitea/env")
      ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${statePath "gitea/data"}:/var/lib/gitea"
        "${statePath "gitea/config"}:/etc/gitea"
      ];
      extraOptions = [
        "--ip=${localAddr.gitea}"
      ];
    };

    registry-ui = {
      image = "joxit/docker-registry-ui:main";
      dependsOn = [ "registry-server" ];
      autoStart = true;
      networks = [ "nas" ];
      environment = {
        SINGLE_REGISTRY = "true";
        REGISTRY_TITLE = "Docker Registry UI";
        DELETE_IMAGES = "true";
        SHOW_CONTENT_DIGEST = "true";
        NGINX_PROXY_PASS_URL = "http://registry-server:5000";
        SHOW_CATALOG_NB_TAGS = "true";
        CATALOG_MIN_BRANCHES = "1";
        CATALOG_MAX_BRANCHES = "1";
        TAGLIST_PAGE_SIZE = "100";
        REGISTRY_SECURED = "false";
        CATALOG_ELEMENTS_LIMIT = "1000";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
      ];
      extraOptions = [
        "--ip=${localAddr.registry-ui}"
      ];
    };

    registry-server = {
      image = "registry:3";
      autoStart = true;
      networks = [ "nas" ];
      environment = {
        REGISTRY_HTTP_HEADERS_Access-Control-Allow-Origin = "[https://hub.lifeym.xyz]";
        REGISTRY_HTTP_HEADERS_Access-Control-Allow-Methods = "[HEAD,GET,OPTIONS,DELETE]";
        REGISTRY_HTTP_HEADERS_Access-Control-Allow-Credentials = "[true]";
        REGISTRY_HTTP_HEADERS_Access-Control-Allow-Headers = "[Authorization,Accept,Cache-Control]";
        REGISTRY_HTTP_HEADERS_Access-Control-Expose-Headers = "[Docker-Content-Digest]";
        REGISTRY_STORAGE_DELETE_ENABLED = "true";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${statePath "docker_registry/data"}:/var/lib/registry"
      ];
      extraOptions = [
        "--ip=${localAddr.registry-server}"
      ];
    };
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
}
