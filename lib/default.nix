{
  lib,
  nix-darwin,
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

  darwinSystem = { system, mkSpecialArgs, hostName, modules }:
    nix-darwin.lib.darwinSystem {
      modules = nixModulePath.darwin.base
        ++ modules ++ [{nixpkgs.hostPlatform = system;}];
      specialArgs = (mkSpecialArgs system) // { inherit hostName; };
    };

  nixModulePath =
  let
    modulesPath = lib.path.append ../modules;
  in
  {
    nixos = { # Base modules must be included in all systems
      base = [
        (modulesPath "base/nixos-base.nix")
      ];

      wsl = [
        (modulesPath "base/nixos-wsl.nix")
      ];

      # Install docker in rootless mode
      dockerRootless = [
        (modulesPath "nixos/docker-rootless.nix")
      ];

      podman = [
        (modulesPath "nixos/podman.nix")
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

  systemdService = {
    mkMariaBackup = {
      containerName,
      backupDir,
      databases,
      pkgs,
      backend ? "docker",
      dbUserFile,
      dbPasswordFile,
      keepDays ? 14,
    }:
    let
      engine = assert builtins.elem backend [ "podman" "docker" ]; backend;
    in {
      description = "Backup MariaDB Docker Container (${containerName})";
      wants = [ "${engine}.service" ];
      after = [ "${engine}.service" ];
      script = ''
        export PATH=${pkgs.${engine}}/bin:${pkgs.coreutils}/bin:${pkgs.zstd}/bin:$PATH
        BACKUP_DIR="${backupDir}"
        mkdir -p "$BACKUP_DIR"
        DATE=$(date +%Y%m%d_%H%M%S)
        DB_USER="$(cat ${dbUserFile})"
        DB_PASSWORD="$(cat ${dbPasswordFile})"

        ${builtins.concatStringsSep "\n" (map (db: ''
          echo "正在备份 ${containerName} 的数据库: ${db}..."
          ${engine} exec ${containerName} mariadb-dump \
            --single-transaction \
            --quick \
            -u $DB_USER \
            -p"$DB_PASSWORD" \
            ${db} | zstd -o "$BACKUP_DIR/${db}_$DATE.sql.zst"

          if [ $? -eq 0 ]; then
            echo "备份数据库: ${db} 成功！"
          else
            echo "备份数据库: ${db} 出错！" >&2
            if [ -f "$BACKUP_DIR/${db}_$DATE.sql.zst" ]; then
              rm -f "$BACKUP_DIR/${db}_$DATE.sql.zst"
            fi
          fi

          find "$BACKUP_DIR" -name "${db}_*.sql.zst" -mtime +${toString keepDays} -delete
        '') databases)}
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };
}
