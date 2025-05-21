{ lib, pkgs-unstable, ... }:

{
  imports = [
    ./base.nix
    ./zram.nix
  ];

  nix.settings.trusted-users = [ "@wheel" ];
  nix.channel.enable = false; # Disable the NixOS channel, as we are using flakes

  # Limit the number of generations to keep
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

  # If mounting a filesystem fails, then you will be force to enter a sulogin shell(emergency mode) without
  # network. That means you can not rebuild configuration.nix forever, but you need nixos-rebuild to correct the /etc/fstab...
  # So, the best way is to disable emergency mode.
  systemd.enableEmergencyMode = false;

  fonts.packages = with pkgs-unstable; [
    #(nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    nerd-fonts.meslo-lg
    source-han-sans # 思源黑体
    source-han-serif # 思源宋体
    sarasa-gothic
  ];
}
