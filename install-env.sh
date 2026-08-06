#!/bin/sh

nix shell --experimental-features 'nix-command flakes' --substituters 'https://mirror.sjtu.edu.cn/nix-channels/store' nixpkgs#gnumake nixpkgs#git
