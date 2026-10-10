{
  pkgs ? import <nixpkgs> { },
}:
with pkgs;
mkShell {
  buildInputs = [
    go-task
    git
    treefmt
    nixfmt
    statix
    deadnix
    nickel
  ];

  shellHook = ''
    task --version
    git version
  '';
}
