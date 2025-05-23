{ lib, pkgs, pkgs-unstable, nixos-wsl, ... }:


{
  imports = [
    # See https://nix-community.github.io/NixOS-WSL/how-to/nix-flakes.html
    nixos-wsl.nixosModules.default
    ./base.nix
    ./zram.nix
  ];

  wsl.enable = true;
  nix.settings.trusted-users = [ "@wheel" ];
  nix.channel.enable = false; # Disable the NixOS channel, as we are using flakes

  fonts.packages = with pkgs-unstable; [
    #(nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
    nerd-fonts.meslo-lg
    source-han-sans # 思源黑体
    source-han-serif # 思源宋体
    sarasa-gothic
  ];
}