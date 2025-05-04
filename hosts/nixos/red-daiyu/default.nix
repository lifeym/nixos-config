# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  pkgs-stable,
  pkgs-unstable,
  ...
}:
let
  hostName = "red-daiyu";
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../nixos-base.nix
  ];

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
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [(pkgs.OVMF.override {
          secureBoot = true;
          tpmSupport = true;
        }).fd];
      };
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
    proxy.default = "192.168.0.6:10809";
    proxy.noProxy = "127.0.0.1,localhost,internal.domain,local,baidu.com,edu.cn";
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
        networkConfig = {
          DHCP = "yes";
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

  # Enable sound.
  #hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.defaultUserShell = pkgs.zsh;
  users.users.lifeym = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [];
  };

  users.users.minidlna = {
    extraGroups = [ "users" ]; # so minidlna can access the files.
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # utilities
    bat
    chezmoi
    clipboard-jh
    dua
    fzf
    gh
    git
    gnumake
    go-task
    htop
    neovim
    nushell
    restic # backup tool
    ripgrep
    shellcheck
    starship
    thefuck
    tmux
    vifm
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    yazi
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
  services.openssh.enable = true;
  services.sshd.enable = true;

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

      # Apple Time Machine
      "tm_share" = {
          "path" = "/mnt/data/lib/samba/tm_share";
          "valid users" = "lifeym";
          "public" = "no";
          "writeable" = "yes";
          # "force user" = "username";
          "fruit:aapl" = "yes";
          "fruit:time machine" = "yes";
          "vfs objects" = "catia fruit streams_xattr";
      };
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

  services.k3s = {
    enable = true;
    role = "server";
    #package = pkgs-unstable.k3s_1_31; # Package to use, when updating, to follow k8s version skrew.
    extraFlags = [
    # "--debug" # Optionally add additional args to k3s
      "--flannel-backend none"
      "--cluster-cidr=10.42.0.0/16"
      "--cluster-domain=cluster.local"
      "--tls-san 192.168.0.6 cluster.local"
      "--disable traefik servicelb"
      "--disable-network-policy"
      "--embedded-registry"
      "--write-kubeconfig-mode 644"
      "--token symphony"
    ];
  };

  services.nfs.server = {
    enable = true;
    exports = ''
    # /export         192.168.1.10(rw,fsid=0,no_subtree_check) 192.168.1.15(rw,fsid=0,no_subtree_check)
    /mnt/data/nfs/k8s/mysql8 192.168.0.6(rw,nohide,insecure,no_subtree_check)
    /mnt/data/nfs/k8s/postgres15 192.168.0.6(rw,nohide,insecure,no_subtree_check)
    /mnt/data/nfs/k8s/pv 192.168.0.6(rw,nohide,insecure,no_subtree_check)
    /mnt/data/nfs/k8s/gitea 192.168.0.6(rw,nohide,insecure,no_subtree_check)
    '';
  };

  # k3s default private registry file
  # See: https://docs.k3s.io/cli/server
  environment.etc."rancher/k3s/registries.yaml".text = ''
  mirrors:
    docker.elastic.co:
      endpoint:
        - "https://elastic.m.daocloud.io"
    docker.io:
      endpoint:
        - "https://docker.m.daocloud.io"
    gcr.io:
      endpoint:
        - "https://gcr.m.daocloud.io"
    ghcr.io:
      endpoint:
        - "https://ghcr.m.daocloud.io"
    k8s.gcr.io:
      endpoint:
        - "https://k8s-gcr.m.daocloud.io"
    registry.k8s.io:
      endpoint:
        - "https://k8s.m.daocloud.io"
    mcr.microsoft.com:
      endpoint:
        - "https://mcr.m.daocloud.io"
    nvcr.io:
      endpoint:
        - "https://nvcr.m.daocloud.io"
    quay.io:
      endpoint:
        - "https://quay.m.daocloud.io"
  '';

  # Open ports in the firewall.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      80
      443
      2049 # nfs v4
      6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
      10809 # v2ray
    ];
    # allowedUDPPorts = [ ... ];
  };

  # v2ray systemd service
  systemd.services.v2ray = {
    description = "V2ray service";
    path = [ pkgs-unstable.v2ray ];
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
    script = "v2ray run -c /mnt/data/lib/v2fly/config.json";
    wantedBy = [ "multi-user.target" ]; # starting a unit by default at boot time
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
