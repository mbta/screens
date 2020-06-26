defmodule Screens.Util do
  @moduledoc false

  def format_time(t) do
    t |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  end

  # Similar to Enum.group_by, except it returns a list of {key, value} tuples instead of a map to maintain order.
  @spec group_by_with_order(Enumerable.t(), (any() -> any())) :: [{any(), [any()]}]
  def group_by_with_order(enumerable, key_fun) do
    enumerable
    |> Enum.reduce([], fn entry, acc ->
      key = key_fun.(entry)

      group =
        acc
        |> List.keyfind(key, 0, {nil, []})
        |> elem(1)

      List.keystore(acc, key, 0, {key, [entry | group]})
    end)
    |> Enum.map(fn {key, group} -> {key, Enum.reverse(group)} end)
  end
end
