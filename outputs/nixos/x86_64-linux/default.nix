{
  mylib,
  nixpkgs,
  ...
} @ inputs:
let
  inherit (nixpkgs) lib;
in
  builtins.listToAttrs # Produce: { red-daiyu = ...; red-baochai = ...; red-yuanchun = ...; }
    (map # For each directory name in the current directory
      (hostName:
        (lib.nameValuePair # Produce: { name = "red-daiyu"; value = import...; }
          hostName
          (import (./. + "/${hostName}") inputs)
        )
      )
      (mylib.listDirNames ./.) # List all directories in the current directory
    )
