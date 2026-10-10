{
  mylib,
  nixpkgs,
  ...
}@inputs:
let
  inherit (nixpkgs) lib;
in
builtins.listToAttrs # Produce: { red-daiyu = ...; red-baochai = ...; red-yuanchun = ...; }
  (
    # For each directory name in the current directory
    map (
      hostName:
      (lib.nameValuePair # Produce: { name = "red-daiyu"; value = import...; }
        hostName
        (import (./. + "/${hostName}") inputs)
      )
    ) (mylib.listDirNames ./.) # List all directories in the current directory
  )
