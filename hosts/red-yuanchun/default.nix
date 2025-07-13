# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  pkgs-stable,
  hostName,
  ...
}:

{
  networking = {
    inherit hostName;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.defaultUserShell = pkgs.zsh;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    chezmoi
    curl
    direnv
    dua
    gh
    git
    gitui
    gnumake
    go-task
    hledger
    hledger-ui
    hledger-web
    neovim
    nixd # nix lsp
    ripgrep
    starship
    termscp
    vifm
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    zoxide
  ];

  programs.zsh.enable = true;

  # For using vscode-server in NixOs, you need to enable the nix-ld feature.
  # See: https://nixos.wiki/wiki/Visual_Studio_Code
  # See: https://github.com/nix-community/nix-ld
  # An alternative is to use: nix-vscode-server
  #   See: https://github.com/nix-community/nixos-vscode-server
  programs.nix-ld.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.sshd.enable = true;

  # Open ports in the firewall.
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      22
      80
      443
    ];
    # allowedUDPPorts = [ ... ];
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
