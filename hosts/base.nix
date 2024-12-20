# Basiclly include all nix settings for NixOS, nix-darwin, and nix package manager.
{ lib, pkgs, ... }:

{
  # Perform garbage collection to reduce disk usage.
  nix.gc = lib.mkDefault {
    automatic = true;
    options = "--delete-older-than 1w";
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # SJTUG contains not only nixos, but also nix-darwin caches
    substituters = [ "https://mirror.sjtu.edu.cn/nix-channels/store" ];

    # Optimize storage
    # See also:
    # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
    auto-optimise-store = lib.mkDefault true;
  };
}
