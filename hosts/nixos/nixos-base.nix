{ lib, pkgs, ... }:

{
  imports = [
    ../base.nix
  ];

  # Limit the number of generations to keep
  boot.loader.systemd-boot.configurationLimit = lib.mkDefault 5;
  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    sarasa-gothic
  ];
}
