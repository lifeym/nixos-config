{
  nixpkgs,
  #nixpkgs-unstable,
  nixpkgs-stable,
  nixos-wsl,
  mylib,
  ...
}:

{
  # Output configuration for the system.

  # Use nixpkgs-stable for building the system.
  systemNixPkgs = nixpkgs;

  # Install extra modules for the system.
  extraModules = mylib.nixModulePath.nixos.wsl;
}
