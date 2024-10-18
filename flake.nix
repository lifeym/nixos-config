{
  description = "NixOS configs";

  # the nixConfig here only affects the flake itself, not the system configuration!
  nixConfig = {
    # Only useful for first time, you may config system wild substituter after installation.
    # Uncomment below lines for first time installing in china.
    # extra-substituters = [
    #   "https://mirror.sjtu.edu.cn/nix-channels/store"
    # ];
  };

  inputs = {
    # Official NixOS package source, using nixos's unstable branch by default
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable-small";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    # nix-darwin
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      nix-darwin,
      ...
    }@inputs:
    let
      utils = import ./lib.nix { lib = nixpkgs.lib; };

      # Output: devShells."${system}".default
      # Run: `nix devlop` or `nix-shell` to enter the dev shell.
      # Then you can use `task` and `git` to peform the installation.
      devShells = utils.eachDefaultSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = import ./shell.nix { inherit pkgs; };
        }
      );

      genSpecialArgs =
        system:
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
    in
    {
      inherit devShells;

      nixosConfigurations = {
        # desktop vm (vmware) for test.
        red-yuanchun =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            # system = "x86_64-linux";
            inherit system;
            specialArgs = genSpecialArgs system;
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
