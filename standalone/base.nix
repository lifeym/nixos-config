{ lib, pkgs, pkgs-unstable, ... }:

{
  fonts.fontconfig.enable = true;
  home.packages = with pkgs-unstable; [
    nerd-fonts.meslo-lg
    nerd-fonts.blex-mono
    sarasa-gothic
  ];
}
