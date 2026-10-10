{
  global = {
    excludes = [
      "**/flack.lock",
      "**/hardware-configuration.nix",
      "Taskfile.yml",
      ".git",
      ".vscode"
    ]
  },

  formatter =
    let includesNix = ["*.nix"]
    in
    {
      nickel = {
        command = "nickel",
        options = ["format"],
        includes = ["*.ncl"]
      },

      nixfmt = {
        # Command to execute
        command = "nixfmt",
        # Command-line arguments for the command
        options = [],
        # Glob pattern of files to include
        includes = includesNix,
        # Glob patterns of files to exclude
        excludes = [],
        # Controls the order of application when multiple formatters match the same file
        # Lower the number, the higher the precedence
        # Default is 0
        priority = 1,
      },

      statix = {
        command = "statix",
        options = ["check"],
        includes = includesNix,
        priority = 2,
        no-positional-arg-support = true
      },

      deadnix = {
        command = "deadnix",
        # options = ["--fail"],
        includes = includesNix,
        priority = 3,
        no-positional-arg-support = true
      }
    }
}
