{
  description = "NixOS configs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ...}@attrs: {
    nixosConfigurations = {
      red-chamber-lin-daiyu = let
        myargs = {
          username = "lifeym";
        };
      in
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = attrs // { inherit myargs; };
          modules = [
            ./hosts/red-chamber-lin-daiyu
          ];
        };
    };
  };
}
