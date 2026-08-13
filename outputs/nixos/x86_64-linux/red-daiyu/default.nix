{
  #nixpkgs,
  #nixpkgs-unstable,
  nixpkgs-stable,
  mylib,
  sops-nix-stable,
  ...
}:

{
  # Output configuration for the system.

  # Use nixpkgs-stable for building the system.
  systemNixPkgs = nixpkgs-stable;

  # Install extra modules for the system.
  extraModules = mylib.nixModulePath.nixos.podman
    ++ [ sops-nix-stable.nixosModules.sops ];
}
