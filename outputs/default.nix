{
  self,
  nixpkgs,
  nix-darwin,
  ...
} @ inputs:
let
  inherit (nixpkgs) lib;
  mylib = import ../lib { inherit lib nix-darwin; };

  # Output: devShells."${system}".default
  # Run: `nix devlop` or `nix-shell` to enter the dev shell.
  # Then you can use `task` and `git` to peform the installation.
  devShells = mylib.eachDefaultSystem (
    system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      default = import ../shell.nix { inherit pkgs; };
    }
  );

  mkSpecialArgs =
    system:
    inputs
    // {
      inherit mylib;

      # use unstable branch for some packages to get the latest updates
      pkgs-unstable = import inputs.nixpkgs-unstable {
        inherit system; # refer the `system` parameter form outer scope recursively
        # To use chrome, we need to allow the installation of non-free software
        config.allowUnfree = true;
      };
      pkgs-stable = import inputs.nixpkgs-stable {
        inherit system;
        # To use chrome, we need to allow the installation of non-free software
        config.allowUnfree = true;
      };
    };

  moduleArgs = inputs // { inherit lib mylib mkSpecialArgs; };
in
{
  inherit devShells;

  nixosConfigurations = import ./nixos moduleArgs;
  darwinConfigurations = import ./darwin moduleArgs;
}
