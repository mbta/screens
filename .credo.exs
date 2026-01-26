%{
  configs: [
    %{
      name: "default",
      requires: ["lib/screens/checks/**/*.ex"],
      files: %{
        included: ["lib/", "test/"],
        excluded: []
      },
      checks: [
        # Custom checks
        {Screens.Checks.UntestableDateTime, files: %{excluded: "test/"}},

        # Disable some checks enabled by default
        {Credo.Check.Design.AliasUsage, false},
        {Credo.Check.Refactor.CyclomaticComplexity, false},
        {Credo.Check.Refactor.Nesting, false}
      ]
    }
  ]
}
