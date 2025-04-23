{
  pkgs,
  pkgs-stable,
  lib,
  ...
}:

{
  imports = [
    ../darwin-base.nix
  ];

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    ###

    # utilities
    bat
    chezmoi
    clipboard-jh # nice cipboard cli
    dua
    fzf
    gnumake
    go-task
    hledger
    htop
    neovim
    nmap
    nushell
    p7zip
    rclone
    restic # backup tool
    ripgrep
    shellcheck
    starship
    termscp
    thefuck
    tmux
    vifm # most confortable vim like file manager
    vim
    xz
    yazi # blazing fast file manager
    zoxide

    ###

    # vm/container related
    docker-client
    qemu
    colima

    ###

    # develop tools
    direnv
    difftastic # nice external diff not only for git
    gh
    git
    git-credential-manager
    gitui
    jq
    nixd
    nixfmt-rfc-style
    yq

    ###

    # dbcli
    litecli
    mycli
    pgcli

    # k8s tools
    argocd
    k9s
    kubectl
    kubeseal
    kustomize
    minikube
    tektoncd-cli
  ];

  homebrew.enable = true;
  homebrew.taps = [
    "homebrew/bundle"
    "homebrew/services"
    "wez/wezterm"
  ];

  homebrew.brews = [
    "docker-credential-helper"
  ];

  homebrew.casks = [
    "dbeaver-community"
    "google-chrome"
    "joplin"
    "mysqlworkbench"
    "qbittorrent"
    "qq"
    "syncthing"
    "vagrant"
    "vagrant-vmware-utility"
    "visual-studio-code"
    "wezterm"
  ];

  environment.variables = {
    EDITOR = "vim";
    XDG_CONFIG_HOME = "$HOME/.config";
    VIFM = "$HOME/.config/vifm";
  };

  # DO NOT use services.nix-daemon.enabled = true,
  # if nix was installed by a installer(eg: determinate nix-installer).
  # nix.useDaemon = true;
  # nix.package = pkgs.nix;

  # Nix linux-builder settings.
  nix.linux-builder.enable = true;

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs = {
    zsh.enable = true; # default shell on catalina
    nix-index.enable = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
    nerd-fonts.blex-mono
    # nerd-fonts.IBMPlexMono
    sarasa-gothic
  ];

  # Set Git commit hash for darwin-version.
  # system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;
  system.defaults.dock.show-recents = false;
  system.defaults.dock.autohide = true;

  security.pam.enableSudoTouchIdAuth = true;
}
