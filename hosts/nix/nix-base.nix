{ lib, pkgs, pkgs-unstable, ... }:

{
  #imports = [
  #  ../base.nix
  #];

  fonts.fontconfig.enable = true;
  home.packages = with pkgs-unstable; [
    nerd-fonts.meslo-lg
    nerd-fonts.blex-mono
    sarasa-gothic
  ];
}
