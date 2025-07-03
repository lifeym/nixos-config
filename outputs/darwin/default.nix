{
  nixpkgs,
  mylib,
  mkSpecialArgs,
  ...
} @ inputs:
let
  inherit (nixpkgs) lib;
  mkDarwinSystem = hostName: system: modules:
    mylib.darwinSystem {
      inherit hostName system modules mkSpecialArgs;
    };
in
  lib.mergeAttrsList
    (map # Produce: [ { red-daiyu = ...; red-baochai = ...; red-yuanchun = ...; } ... ]
      (system:
        let
          cfgSet = import (./. + "/${system}") ({ inherit system; } // inputs);
        in
          builtins.mapAttrs # Produce: { red-daiyu = ...; red-baochai = ...; red-yuanchun = ...; }
            (hostName: hostCfg:
              (mkDarwinSystem
                hostName
                system
                ( (mylib.mkHostModules hostName (hostCfg.hostModues or null))
                  ++ (hostCfg.extraModules or [])
                )
              ) # Merge extra modules
            )
            cfgSet
      )
      (mylib.listDirNames ./.) # List all directories in the current directory
    )
