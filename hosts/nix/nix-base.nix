{ lib, pkgs, ... }:

{
  imports = [
    ../base.nix
  ];

  fonts.fontconfig.enable = true;
  home.packages = [
    (pkgs.nerdfonts.override { fonts = [ "Meslo" "IBMPlexMono" ]; })
  ];
}
