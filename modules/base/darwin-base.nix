{ lib, pkgs, ... }:

{
  imports = [
    ./base.nix
  ];

  nix.settings.bash-prompt-prefix = lib.mkDefault "(nix:$name)\\040";
  nix.settings.trusted-users = [ "@admin" ];
}
