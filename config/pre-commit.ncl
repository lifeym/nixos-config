{
  repos = [
    {
      repo = "https://github.com/pre-commit/pre-commit-hooks",
      rev = "v6.0.0",
      hooks = [
        {
          id = "end-of-file-fixer",
        },
        {
          id = "trailing-whitespace",
        }
      ],
    },
    {
      repo = "local",
      hooks = [
        {
          id = "treefmt",
          name = "treefmt",
          entry = "task treefmt",
          language = "unsupported",
          pass_filenames = false, # important: since this is a task batch, no filenames needed.
        }
      ],
    }
  ]
}
