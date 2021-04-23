defmodule Screens.Util do
  @moduledoc false

  def format_time(t) do
    t |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  end

  @spec time_period(DateTime.t()) :: :peak | :off_peak
  def time_period(utc_time) do
    {:ok, dt} = DateTime.shift_zone(utc_time, "America/New_York")

    day_of_week = dt |> DateTime.to_date() |> Date.day_of_week()
    weekday? = day_of_week in 1..5

    t = {dt.hour, dt.minute}
    am_rush? = t >= {7, 0} and t < {9, 0}
    pm_rush? = t >= {16, 0} and t <= {18, 30}
    rush_hour? = am_rush? or pm_rush?

    if(weekday? and rush_hour?, do: :peak, else: :off_peak)
  end

  @doc """
  Similar to Enum.group_by, except it returns a list of {key, value} tuples instead of a map to maintain order.
  """
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

  @doc """
  Gets the keys of a struct given the module where the struct is defined.

  Converts the keys to strings by default.
  """
  @spec struct_keys(module(), keyword()) :: list(atom()) | list(String.t())
  def struct_keys(mod, opts \\ []) do
    keys =
      mod
      |> Map.from_struct()
      |> Map.keys()

    if Keyword.get(opts, :as_strings, true) do
      Enum.map(keys, &Atom.to_string/1)
    else
      keys
    end
  end

  @doc """
  Similar to Enum.unzip, except it expects an enumerable of 3-element instead of 2-element tuples.
  """
  @spec unzip3(Enum.t()) :: {[Enum.element()], [Enum.element()], [Enum.element()]}
  def unzip3(enumerable) do
    {list1, list2, list3} =
      Enum.reduce(enumerable, {[], [], []}, fn {el1, el2, el3}, {list1, list2, list3} ->
        {[el1 | list1], [el2 | list2], [el3 | list3]}
      end)

    {:lists.reverse(list1), :lists.reverse(list2), :lists.reverse(list3)}
  end
end
