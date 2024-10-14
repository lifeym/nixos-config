{
  description = "NixOS configs";

  inputs = {
    # Official NixOS package source, using nixos's unstable branch by default
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable-small";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, ...}@inputs:
  let
    genSpecialArgs = system:
      inputs
      // {
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
  in {
    nixosConfigurations = {
      red-yuanchun =
      let
        system = "x86_64-linux";
        myargs = {
          username = "lifeym";
        };
      in
        nixpkgs.lib.nixosSystem {
          # system = "x86_64-linux";
          inherit system;
          specialArgs = inputs // { inherit myargs; };
          modules = [
            ./hosts/nixos/red-yuanchun
          ];
        };
    };

    darwinConfigurations = {
      sansan =
      let
        system = "x86_64-darwin";
      in
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = genSpecialArgs system;
          modules = [
            ./hosts/nix-darwin/sansan
          ];
        };
    };
  };
}