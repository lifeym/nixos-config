{ pkgs, pkgs-stable, lib, ... }:

{
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
      # see: https://github.com/NixOS/nixpkgs/issues/348309
      # has not fixed yet(unstable)
      # go-task
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
      mycli
      nixd
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
    ] ++ [
      # see: https://github.com/NixOS/nixpkgs/issues/348309
      # has not fixed yet(unstable)
      # use stable version instead
      pkgs-stable.go-task
    ];

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

    # Necessary for using flakes on this system.
    nix.settings.experimental-features = "nix-command flakes";
    nix.settings.bash-prompt-prefix = "(nix:$name)\\040";
    nix.settings.substituters = [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];
    nix.settings.trusted-users = [ "@admin" ];

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
