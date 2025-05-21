{
  description = "NixOS configs";

  # the nixConfig here only affects the flake itself, not the system configuration!
  nixConfig = {
    # Only useful for first time, you may config system wild substituter after installation.
    # Uncomment below lines for first time installing in china.
    #extra-substituters = [
    #  "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    #];
  };

  outputs = inputs: import ./outputs inputs;
  inputs = {
    # Official NixOS package source, using nixos's unstable branch by default
    # Large channels (nixos-24.05, nixos-unstable) provide binary builds for the full breadth of Nixpkgs.
    # Small channels (nixos-24.05-small, nixos-unstable-small) are identical to large channels, but contain fewer binaries.
    # This means they update faster, but require more to be built from source.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    # nix-darwin
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };
}
