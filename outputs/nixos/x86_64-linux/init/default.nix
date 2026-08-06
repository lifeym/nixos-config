{
  #nixpkgs,
  #nixpkgs-unstable,
  nixpkgs-stable,
  mylib,
  ...
}:

{
  # Output configuration for the system.

  # Use nixpkgs-stable for building the system.
  systemNixPkgs = nixpkgs-stable;
}
