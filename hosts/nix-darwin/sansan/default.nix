{ pkgs, pkgs-stable, lib, ... }:

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
    ripgrep
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
    gh
    git
    git-credential-manager
    gitui
    jq
    nixd
    nixfmt-rfc-style
    yq

    ###

    # k8s tools
    argocd
    k9s
    kubectl
    kubeseal
    kustomize
    minikube
    tektoncd-cli
  ] ++ (with pkgs-stable; [
    mycli
  ]);

  homebrew.enable = true;
  homebrew.taps = [
    "homebrew/bundle"
    # "homebrew/cask-fonts"
    # "homebrew/cask-versions"
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
    "font-sarasa-gothic"
    "syncthing"
    "vagrant"
    "vagrant-vmware-utility"
    "visual-studio-code"
    "wezterm"
  ];

  environment.variables = {
    EDITOR = "vim";
    VIFM = "$HOME/.config/vifm";
  };

  # DO NOT use services.nix-daemon.enabled = true,
  # if nix was installed by a installer(eg: determinate nix-installer).
  nix.useDaemon = true;
  # nix.package = pkgs.nix;

  # Nix linux-builder settings.
  nix.linux-builder.enable = true;

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina

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
