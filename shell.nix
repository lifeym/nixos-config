{
  pkgs ? import <nixpkgs> { },
}:
with pkgs;
mkShell {
  buildInputs = [
    go-task
    git

    # fmt tools
    treefmt

    # nix related format lint tools
    nixfmt
    statix
    deadnix

    # config tools
    nickel
    nls # nickel-language-server

    pre-commit
  ];

  shellHook = ''
    task pre-commit-install
  '';
}
