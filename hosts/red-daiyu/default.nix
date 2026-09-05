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
  consts = import ./consts.nix;
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    # 基础设施
    ./svc/msmtp.nix
    ./svc/ncps.nix
    ./svc/samba.nix
    ./svc/nginx.nix
    ./svc/fail2ban.nix
    ./svc/easytier.nix
    ./svc/restic.nix

    # apps
    ./svc/woodpecker.nix
    ./svc/navidrome.nix
    ./svc/paperless.nix
    ./svc/transmission.nix
    ./svc/grocy.nix
    ./svc/mealie.nix
    ./svc/einvault.nix
  ];

  # Enable OpenGL
  # See: https://wiki.nixos.org/wiki/AMD_GPU
  # See: https://wiki.nixos.org/wiki/Graphics#OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.lvm.enable = true;
  boot.initrd.kernelModules = [
    "dm-cache"
    "dm-cache-smq"
    "dm-persistent-data"
    "dm-snapshot"
    "dm-cache-default" # when using volumes set up with lvmcache
  ];

  environment.etc."lvm/lvm.conf.d/cache-activation-fix.conf".text = ''
    activation {
      udev_sync = 0
      udev_rules = 0
    }

    devices {
      obtain_device_list_from_udev = 0
    }
  '';

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
  boot.swraid = let
    appTokenFile = config.sops.secrets."pushover/apps/red-daiyu".path;
    userKeyFile = config.sops.secrets."pushover/user-key".path;

    # Create a lightweight shell script to parse mdadm event details
    mdadmPushoverAlert = pkgs.writeShellScript "mdadm-pushover" ''
      EVENT="$1"
      DEVICE="$2"
      COMPONENT="$3"

      # Construct a descriptive message payload
      MESSAGE="MDADM Event: $EVENT detected on $DEVICE"
      if [ -n "$COMPONENT" ]; then
        MESSAGE="$MESSAGE (Component affected: $COMPONENT)"
      fi

      # Dispatch to Pushover API
      ${pkgs.curl}/bin/curl -s https://api.pushover.net/1/messages.json \
        -F "token=$(cat ${appTokenFile})" \
        -F "user=$(cat ${userKeyFile})" \
        -F "title=⚠️ RAID Alert - $(hostname)" \
        -F "message=$MESSAGE" \
        -F "priority=1" \
    '';
  in {
    enable = true;
    mdadmConf = ''
      ARRAY /dev/md/openSUSE:1 metadata=1.2 UUID=890c5d74:2a8b8f7f:01c80f44:f4ed2786
      MAILADDR 8r92uvybh6@pomail.net
      MAILFROM lifeym@qq.com
      PROGRAM ${mdadmPushoverAlert}
    '';
  };

  services.lvm.boot.thin.enable = true; # when using thin provisioning or caching

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/9734a151-32f3-4986-ba99-d560d4bb572b";
    fsType = "xfs";
    options = [
      "nofail"
      "noatime"
      "nodev"
      "defaults"
    ];
  };

  # fileSystems."/mnt/store" = {
  #   device = "/dev/disk/by-uuid/420525b9-5ad6-4844-9dfd-e7d9cef05462";
  #   fsType = "xfs";
  #   options = [
  #     "nofail"
  #     "x-systemd.automount" # 按需挂载
  #     "x-systemd.idle-timeout=60s"
  #     "x-systemd.device-timeout=30s"
  #     "defaults"
  #   ];
  # };

  fileSystems."/mnt/downloads" = {
    device = "/dev/disk/by-uuid/bee914aa-99e5-4329-9e62-dfc26f7f0e85";
    fsType = "xfs";
    options = [
      "nofail"
      "noatime"
      "nodev"
      "x-systemd.automount" # 按需挂载
      "x-systemd.idle-timeout=60s"
      "x-systemd.device-timeout=30s"
      "defaults"
    ];
  };

  fileSystems."/mnt/fast" = {
    device = "/dev/disk/by-uuid/2ae126bf-962e-4a4c-b292-f60e65e9eec5";
    fsType = "ext4";
    options = [
      "nofail"
      "noatime"
      "nodev"
      "x-systemd.automount" # 按需挂载
      "x-systemd.idle-timeout=60s"
      "x-systemd.device-timeout=30s"
      "defaults"
    ];
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    inherit hostName;

    # Configure network proxy if necessary
    proxy.default = consts.proxyCfg.httpProxy;
    proxy.noProxy = consts.proxyCfg.noProxy; #"localhost,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,internal.domain,local,baidu.com,edu.cn";
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
        address = consts.networkAddress;
        networkConfig = {
          # DHCP = "ipv4"; # use ipv4 only. ipv6 uses ipv6RA, not dhcpv6
          IPv4Forwarding = true;
          # IPv6Forwarding = true;
          IPv6AcceptRA = true;
          IPv6PrivacyExtensions = false; # keep the audit clean...
          DNS = [
            "192.168.0.1"
            "114.114.114.114"
          ];
        };

        routes = [
          { Gateway = "192.168.0.1"; }
        ];

        ipv6AcceptRAConfig = {
          Token = "::6";
          UseGateway = true;
          # UseRoutes = true;
          UseDNS = false;
        };
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
      "smtp/token" = {};
      "paperless-secret-key" = {};
      "pushover/apps/red-daiyu" = {};
      "pushover/user-key" = {};
    };
    templates."paperless-secret-key".content = ''
      PAPERLESS_SECRET_KEY="${config.sops.placeholder.paperless-secret-key}"
    '';
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
    listenAddresses = with consts.roles.red-daiyu; [
      { addr = ipv4; port = 22; }
      { addr = ipv6; port = 22; }
    ];
    settings = {
      PermitRootLogin = "no"; # Disable root login via SSH.
      PasswordAuthentication = false; # Disable password authentication.
      UseDns = true;
    };
  };

  systemd.services.sshd = {
    requires = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };

  services.minidlna = {
    enable = true;
    settings = {
      friendly_name = "red-daiyu";
      inotify = "yes"; # enable inotify monitoring to automatically discover new files.
      log_level = "error"; # reduce disk io and usage.
      media_dir = [
        "V,/mnt/downloads"
      ];
    };
    openFirewall = true;
  };

  systemd.services.minidlna = {
    requires = [
      "mnt-downloads.mount"
    ];
    after = [
      "mnt-downloads.mount"
    ];
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
      environmentFile = "${consts.statePath}acme/tencent";
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
      consts.proxyCfg.port # v2ray
    ] ++ lib.range 5900 5920; # Reserve5900~5920 for vnc ports
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
    requires = [
      "podman.service" # Thanks to the systemd-networkd, or v2ray cannot auto start with network.target
    ];
    after = [
      "podman.service" # Thanks to the systemd-networkd, or v2ray cannot auto start with network.target
    ];
    wantedBy = [ "multi-user.target" ];
    script = ''
      ${pkgs.podman}/bin/podman network exists nas || \
      ${pkgs.podman}/bin/podman network create nas --subnet=10.33.0.0/24 --gateway=10.33.0.1
    '';
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
        "${consts.statePath}cwa/config:/config"
        "${consts.statePath}cwa/ingest:/cwa-book-ingest"
        "/mnt/data/calibre-library:/calibre-library"
      ];
      extraOptions = [
        "--ip=${consts.services.cwa.addr}"
      ];
    };

    mariadb = {
      image = "mariadb:12";
      autoStart = true;
      networks = [ "nas" ];
      environmentFiles = [
        # Sample:
        # MARIADB_ROOT_PASSWORD=YourInitPassword
        ("${consts.statePath}mariadb/env")
      ];
      volumes = [ # /path/on/host:/path/inside/container
        "/etc/localtime:/etc/localtime:ro"
        "${consts.statePath}mariadb/mysql:/var/lib/mysql"
        "${consts.statePath}mariadb/conf.d:/etc/mysql/conf.d:ro"
      ];
      extraOptions = [
        "--ip=${consts.services.mariadb.addr}"
      ];
    };

    "cjf-mariadb" = {
      image = "mariadb:12";
      autoStart = true;
      networks = [ "nas" ];
      environmentFiles = [
        # Sample:
        # MARIADB_ROOT_PASSWORD=YourPassword
        ("${consts.statePath}cjf/mariadb/env")
      ];
      volumes = [ # /path/on/host:/path/inside/container
        "/etc/localtime:/etc/localtime:ro"
        "${consts.statePath}cjf/mariadb/mysql:/var/lib/mysql"
        "${consts.statePath}cjf/mariadb/conf.d:/etc/mysql/conf.d:ro"
      ];
      extraOptions = [
        "--ip=${consts.services.cjf-mariadb.addr}"
      ];
    };

    gitea = {
      image = "docker.gitea.com/gitea:1.27-rootless";
      pull = "newer";
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
        ("${consts.statePath}gitea/env")
      ];
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        "${consts.statePath}gitea/data:/var/lib/gitea"
        "${consts.statePath}gitea/config:/etc/gitea"
      ];
      extraOptions = [
        "--ip=${consts.services.gitea.addr}"
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
        "--ip=${consts.services.registry-ui.addr}"
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
        "${consts.statePath}docker_registry/data:/var/lib/registry"
      ];
      extraOptions = [
        "--ip=${consts.services.registry-server.addr}"
      ];
    };
  };

  environment.etc."containers/containers.conf.d/proxy.conf".text = ''
    [engine]
    env = [
      "HTTP_PROXY=${consts.proxyCfg.httpProxy}",
      "HTTPS_PROXY=${consts.proxyCfg.httpProxy}",
      "NO_PROXY=${consts.proxyCfg.noProxy}"
    ]
  '';

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
