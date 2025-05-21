{
  lib,
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
in
rec {
  inherit
    eachDefaultSystem
    eachDefaultDarwin
    eachDefaultLinux
    ;

  # List all Nix modules under the path,
  # And return a list of names
  # This includes .nix files and directories
  # but ignores default.nix files
  # This is useful for generating a list of modules
  listModuleNames = path:
    builtins.attrNames
      (lib.attrsets.filterAttrs
        (path: _type:
          (_type == "directory") # include directories
          || (
            (path != "default.nix") # ignore default.nix
            && (lib.strings.hasSuffix ".nix" path) # include .nix files
          )
        )
        (builtins.readDir path)
      );

  # List all Nix modules under the path,
  # And return a list of paths
  # This includes .nix files and directories
  # but ignores default.nix files
  # This is useful for generating a list of modules
  listModulePaths = path:
    builtins.map
      (f: (path + "/${f}"))
      (listModuleNames path);

  # List directories under the path
  listDirNames = path:
    builtins.attrNames
      (lib.attrsets.filterAttrs
        (path: _type:
          (_type == "directory") # include directories
        )
        (builtins.readDir path)
      );

  listDirPaths = path:
    builtins.map
      (f: (path + "/${f}"))
      (listModuleNames path);

  mapModules = f: path:
    builtins.mapAttrs
      (name: value: (f name (path + "/${name}")))
      (lib.attrsets.filterAttrs
        (path: _type:
          (_type == "directory") # include directories
          || (path != "default.nix") # ignore default.nix
        )
        (builtins.readDir path)
      );

  # Build the "nixosSystem" structure
  # This is used to build the NixOS system
  nixosSystem = { systemNixPkgs, system, mkSpecialArgs, hostName, modules }:
    systemNixPkgs.lib.nixosSystem {
      inherit system;
      modules = nixModulePath.nixos.base
        ++ modules;
      specialArgs = (mkSpecialArgs system) // { inherit hostName; };
    };

  nixModulePath =
  let
    modulesPath = lib.path.append ../modules;
  in
  {
    nixos = { # Base modules must be included in all systems
      base = [
        # (modulesPath "base/base.nix")
        (modulesPath "base/nixos-base.nix")
      ];

      # Install docker in rootless mode
      dockerRootless = [
        (modulesPath "nixos/docker-rootless.nix")
      ];
    };

    darwin = {
      # Base modules must be included in all systems
      base = [
        # (modulesPath "base/base.nix")
        (modulesPath "base/darwin-base.nix")
      ];
    };
  };

  mkHostModules = hostName: hostPathList:
  let
    hostModulePath = lib.path.append ../hosts;
  in
    if hostPathList == null || hostPathList == [] then
      [ (hostModulePath "${hostName}")
      ]
    else
      map
        (hostPath:
          (hostModulePath "${hostPath}")
        )
        hostPathList;
}
