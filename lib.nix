{
  lib
}:
let
  darwinSystems = [
    "aarch64-darwin"
    "x86_64-darwin"
  ];
  linuxSystems = [
    "aarch64-linux"
    "x86_64-linux"
  ];
  defaultSystems = darwinSystems ++ linuxSystems;
  eachDefaultSystem = lib.genAttrs defaultSystems;
  eachDefaultDarwin = lib.genAttrs darwinSystems;
  eachDefaultLinux = lib.genAttrs linuxSystems;
in {
  inherit
    eachDefaultSystem
    eachDefaultDarwin
    eachDefaultLinux;
}
