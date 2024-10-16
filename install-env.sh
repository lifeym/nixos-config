#!/bin/sh

nix shell --experimental-feature 'nix-command flakes' --substituters 'https://mirror.sjtu.edu.cn/nix-channels/store' nixpkgs#gnumake nixpkgs#git
