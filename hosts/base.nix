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
    substituters = [ 
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirror.iscas.ac.cn/nix-channels/store"
      #"https://mirror.sjtu.edu.cn/nix-channels/store"
    ];

    # Optimize storage
    # See also:
    # https://nixos.org/manual/nix/stable/command-ref/conf-file.html#conf-auto-optimise-store
    # `nix.settings.auto-optimise-store` is known to corrupt the Nix Store, nix-darwin use `nix.optimise.automatic` instead.
    # auto-optimise-store = lib.mkDefault true;
  };
}
