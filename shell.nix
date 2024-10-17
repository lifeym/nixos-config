{ pkgs ? import <nixpkgs> { } }:
with pkgs;
mkShell {
  buildInputs = [
    go-task
    git
  ];

  shellHook = ''
    task --version
    git version
  '';
}
