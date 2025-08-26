# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  mylib,
  pkgs,
  pkgs-stable,
  pkgs-unstable,
  hostName,
  ...
}:
let
  proxyCfg = {
    httpProxy = "http://192.168.0.6:10809";
    port = 10809;
    noProxy = "localhost,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,internal.domain,local,baidu.com,edu.cn";
  };
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # load tcp_bbr module for enabling bbr in sysctl.
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    # using bbr
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.useOSProber = true;

  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
    "aarch64_be-linux"
    "armv6l-linux"
    "armv7l-linux"
  ];

  networking = {
    inherit hostName;
    networkmanager.enable = true;

    # Configure network proxy if necessary
    proxy.default = proxyCfg.httpProxy;
    proxy.noProxy = proxyCfg.noProxy; #"localhost,127.0.0.0/8,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,internal.domain,local,baidu.com,edu.cn";
  };

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  # Finally, we got fcitx5 to work with KDE Plasma 6.
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      kdePackages.fcitx5-qt
      fcitx5-chinese-addons
      fcitx5-nord # theme
    ];
  };

  # Enable sound.
  #hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "cn";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.defaultUserShell = pkgs.zsh;
  users.users.lifeym = {
    extraGroups = [ "networkmanager" "wheel" "libvirtd" ]; # Enable ‘sudo’ for the user.

    # To keep user service to stay running after a user logs out.
    # See: https://wiki.nixos.org/wiki/Systemd/User_Services
    linger = true;
    packages = with pkgs-unstable; [
      calibre # E-book management application
      digikam # Digital photo management application
      kdePackages.ghostwriter # A Qt Markdown editor
      keepassxc
      logseq
      rustdesk
      thunderbird
      vscode
      wechat-uos
      wpsoffice-cn
      zettlr
    ] ++ (with pkgs;[
      dbeaver-bin # because of dbeaver-ce-unstable uses java 21, which is not installed by pkgs-stable
    ]);
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
    hledger
    hledger-ui
    hledger-web
    htop
    neovim
    nixd
    nushell
    qemu
    restic # backup tool
    ripgrep
    shellcheck
    starship
    termscp
    thefuck
    tmux
    vifm
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    zoxide

    # develop tools
    argocd
    direnv
    difftastic
    ghostty
    git-credential-manager
    gitui
    mycli
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu;
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
  boot.extraModprobeConfig = "options kvm_amd nested=1";

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
  programs.firefox.enable = true;
  programs.virt-manager.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = true; # Open the firewall for SSH connections.
    settings = {
      PermitRootLogin = "no"; # Disable root login via SSH.
      PasswordAuthentication = false; # Disable password authentication.
      UseDns = true;
    };
  };

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Open ports in the firewall.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      80
      8080
      443
    ];
    # allowedUDPPorts = [
    #   21116 # rustdesk
    # ];
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
