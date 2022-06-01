# `use Credo.Check` generates a @moduledoc tag for the module, but Credo isn't smart enough to know that
# credo:disable-for-next-line Credo.Check.Readability.ModuleDoc
defmodule Screens.Checks.UntestableDateTime do
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      Creating representations of "now" within a function's body
      via `DateTime.utc_now/1` and similar functions causes the
      function to be untestable. It's not possible to control the
      "now" value from unit tests, so their outcomes can vary depending
      on when they are run--that is, they become "flaky".

      Instead, the "now" value should be taken as an argument with
      a default value. (Or no default value if it's a private function)
      In normal circumstances, the default value
      will be used, but unit tests can pass their own fixed "now" value
      so that they have full control over the test's outcome.

      Untestable:

          def after_noon_utc?, do: DateTime.utc_now().hour >= 12

      Testable:

          def after_noon_utc?(now \\\\ DateTime.utc_now()), do: now.hour >= 12

      Using the testable function in production code:

          if after_noon_utc?(), do: "Good afternoon", else: "Good morning"

      Testing the testable function:

          morning = ~U[2022-01-01T09:00:00Z]
          afternoon = ~U[2022-01-01T15:00:00Z]

          refute after_noon_utc?(morning)
          assert after_noon_utc?(afternoon)
      """
    ]

  @def_ops [:def, :defp]

  @impl true
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  for def_op <- @def_ops do
    # Matches function definition with or without guards. Passes all blocks of the function body to secondary traverse function.
    # NOTE: In addition to the usual `do` block, a function def can have additional `rescue`, `catch`, `after`, and `else` blocks.
    # We consider all of these to be parts of the function body, so we enforce this check across all blocks.
    defp traverse(
           {unquote(def_op), _, [_func_head_or_guards, body_blocks]} = ast,
           issues,
           issue_meta
         ) do
      new_issues = Credo.Code.prewalk(body_blocks, &traverse_function_body(&1, &2, issue_meta))

      {ast, issues ++ new_issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  @function_denylist [
    {:DateTime, :utc_now},
    {:DateTime, :now},
    {:DateTime, :now!},
    {:Date, :utc_today},
    {:NaiveDateTime, :local_now},
    {:NaiveDateTime, :utc_now},
    {:Time, :utc_now}
  ]

  for {module, function} = mf <- @function_denylist do
    # This function is only called once we're already looking inside a function's body.
    # Any usages of one of the "now" functions that we find here are not allowed.
    defp traverse_function_body(
           {{:., _, [{:__aliases__, _, [unquote(module)]}, unquote(function)]}, meta, args} = ast,
           issues,
           issue_meta
         ) do
      mfa = Tuple.append(unquote(mf), length(args))
      {ast, issues ++ [issue_for(mfa, meta[:line], issue_meta)]}
    end
  end

  defp traverse_function_body(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for({module, function, arity}, line_no, issue_meta) do
    format_issue(
      issue_meta,
      message:
        "To prevent flaky unit tests, a `now` value must be passed as an argument (with a default value if the function is public), not created in the function body.",
      trigger: "#{module}.#{function}/#{arity}",
      line_no: line_no
    )
  end
end
