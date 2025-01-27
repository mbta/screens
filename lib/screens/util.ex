defmodule Screens.Util do
  @moduledoc false

  alias Screens.Config.Cache

  @doc """
  Similar to Enum.group_by, except it returns a list of {key, value} tuples instead of a map to maintain order.
  Order of the groups is determined by the position of the first occurrence of a member of that group.

      iex> Screens.Util.group_by_with_order(0..10, &rem(&1, 3))
      [
        {0, [0, 3, 6, 9]},
        {1, [1, 4, 7, 10]},
        {2, [2, 5, 8]}
      ]

      iex> Screens.Util.group_by_with_order(
             [%{group_id: 2, val: :a}, %{group_id: 1, val: :b}, %{group_id: 2, val: :c}, %{group_id: 1, val: :d}],
             & &1.group_id
           )
      [
        {2, [%{group_id: 2, val: :a}, %{group_id: 2, val: :c}]},
        {1, [%{group_id: 1, val: :b}, %{group_id: 1, val: :d}]},
      ]
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

  @doc """
  Returns a list of elements in an enumerable that occur before the given target value,
  or an empty list if the target is not present in the enumerable.
  """
  @spec slice_before(Enum.t(), any()) :: list()
  def slice_before(enumerable, target) do
    case Enum.find_index(enumerable, &(&1 == target)) do
      nil -> []
      i -> Enum.take(enumerable, i)
    end
  end

  @doc """
  Returns a list of elements in an enumerable that occur after the given target value,
  or an empty list if the target is not present in the enumerable.
  """
  @spec slice_after(Enum.t(), any()) :: list()
  def slice_after(list, target) do
    case Enum.find_index(list, &(&1 == target)) do
      nil -> []
      i -> Enum.drop(list, i + 1)
    end
  end

  @doc """
  Returns a DateTime object parsed from the given string.
  String must already be in ISO8601 format.
  """
  @spec parse_time_string(String.t()) :: DateTime.t()
  def parse_time_string(time) do
    {:ok, dt, _} = DateTime.from_iso8601(time)
    dt
  end

  @doc """
  Takes a list of proper noun strings and
  returns a string (with Oxford comma when necessary)
  """
  @spec format_name_list_to_string([String.t()]) :: String.t()
  def format_name_list_to_string([string]), do: "#{string}"
  def format_name_list_to_string([s1, s2]), do: "#{s1} & #{s2}"

  def format_name_list_to_string(list) do
    list
    |> List.update_at(length(list) - 1, &"& #{&1}")
    |> Enum.join(", ")
  end

  @doc """
  Same as regular string list formatter, but for audio (extra comma for clarity, "and" instead of "&")
  """
  @spec format_name_list_to_string_audio([String.t()]) :: String.t()
  def format_name_list_to_string_audio([string]), do: "#{string}"
  def format_name_list_to_string_audio([s1, s2]), do: "#{s1}, and, #{s2}"

  def format_name_list_to_string_audio(list) do
    list
    |> List.update_at(length(list) - 1, &"and, #{&1}")
    |> Enum.join(", ")
  end

  @doc """
  Returns true if given Time object falls between start_time and end_time.
  """
  def time_in_range?(t, start_time, stop_time) do
    if Time.compare(start_time, stop_time) in [:lt, :eq] do
      # The range exists within a single day starting/ending at midnight
      Time.compare(start_time, t) in [:lt, :eq] and Time.compare(stop_time, t) == :gt
    else
      # The range crosses midnight, e.g. start: 5am, stop: 1am
      Time.compare(start_time, t) in [:lt, :eq] or Time.compare(stop_time, t) == :gt
    end
  end

  @doc """
  Takes route id, returns route type.
  Not the favorite way of getting route type, but useful for property testing.
  """
  @spec route_type_from_id(String.t()) :: atom()
  def route_type_from_id("Green" <> _), do: :light_rail
  def route_type_from_id("Mattapan" <> _), do: :light_rail
  def route_type_from_id("Red"), do: :subway
  def route_type_from_id("Orange"), do: :subway
  def route_type_from_id("Blue"), do: :subway
  def route_type_from_id("CR-" <> _), do: :rail
  def route_type_from_id("Boat-" <> _), do: :ferry
  def route_type_from_id(_), do: :bus

  def outdated?("DUP-" <> _, _), do: false

  def outdated?("TRI-" <> _, _), do: false

  def outdated?(screen_id, client_refresh_timestamp) do
    {:ok, client_refresh_time, _} = DateTime.from_iso8601(client_refresh_timestamp)
    refresh_if_loaded_before_time = Cache.refresh_if_loaded_before(screen_id)

    case refresh_if_loaded_before_time do
      nil -> false
      _ -> DateTime.compare(client_refresh_time, refresh_if_loaded_before_time) == :lt
    end
  end

  def to_set(nil), do: MapSet.new([])
  def to_set(id) when is_binary(id), do: MapSet.new([id])
  def to_set(ids) when is_list(ids), do: MapSet.new(ids)
  def to_set(%MapSet{} = already_a_set), do: already_a_set

  @doc "Shifts a datetime into Eastern time."
  @spec to_eastern(DateTime.t()) :: DateTime.t()
  def to_eastern(datetime), do: DateTime.shift_zone!(datetime, "America/New_York")

  @doc """
  Determines the MBTA service date at a given moment in time.

  The boundary between service dates is 3:00am local time. In the period between midnight and
  3:00am, the calendar date is one day ahead of the service date.
  """
  @spec service_date(DateTime.t()) :: Date.t()
  def service_date(datetime) do
    dt = to_eastern(datetime)
    if dt.hour >= 3, do: DateTime.to_date(dt), else: Date.add(dt, -1)
  end

  @doc """
    Adds a timeout to a function. Mainly used for child processes of a Task.Supervisor
    which don't come with a timeout by default.
  """
  @spec fn_with_timeout((-> val), non_neg_integer()) :: (-> val) when val: any()
  def fn_with_timeout(fun, timeout) do
    fn ->
      _ = :timer.exit_after(timeout, :kill)
      fun.()
    end
  end
end
