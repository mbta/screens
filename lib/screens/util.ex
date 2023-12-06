defmodule Screens.Util do
  @moduledoc false

  alias Screens.Config.Cache
  alias Screens.Vehicles.Carriage

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
  def format_name_list_to_string([s1, s2]), do: "#{s1} and #{s2}"

  def format_name_list_to_string(list) do
    list
    |> List.update_at(length(list) - 1, &"and #{&1}")
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

  @doc """
    Calculates the service day for the given DateTime.
    For context, MBTA service days end at 3am, not at midnight.
    So getting the service day means subtracting 3 hours from the current time.
    To avoid duplicate DateTime calculations existing throughout the code,
    this function will handle the actual calculations needed to get the service day.
  """
  @spec get_service_date_today(DateTime.t()) :: Date.t()
  def get_service_date_today(now) do
    {:ok, now_eastern} = DateTime.shift_zone(now, "America/New_York")

    # If it is at least 3am, the current date matches the service date.
    # If current time is between 12am and 3am, the date has changed but we are still in service for the previous day.
    # That means we need to subtract 1 day to get the current service date.
    if now_eastern.hour >= 3 do
      DateTime.to_date(now_eastern)
    else
      Date.add(now_eastern, -1)
    end
  end

  @spec get_service_date_tomorrow(DateTime.t()) :: Date.t()
  def get_service_date_tomorrow(now) do
    Date.add(get_service_date_today(now), 1)
  end

  def translate_carriage_occupancy_status(%Carriage{occupancy_status: :no_data_available}),
    do: :no_data

  def translate_carriage_occupancy_status(%Carriage{occupancy_status: :not_accepting_passengers}),
    do: :closed

  def translate_carriage_occupancy_status(%Carriage{occupancy_percentage: occupancy_percentage})
      when occupancy_percentage <= 12,
      do: :not_crowded

  def translate_carriage_occupancy_status(%Carriage{occupancy_percentage: occupancy_percentage})
      when occupancy_percentage <= 40,
      do: :some_crowding

  def translate_carriage_occupancy_status(%Carriage{occupancy_percentage: occupancy_percentage})
      when occupancy_percentage > 40,
      do: :crowded

  def translate_carriage_occupancy_status(_), do: nil

  @doc """
    Adds a timeout to a function. Mainly used for child processes of a Task.Supervisor
    which don't come with a timeout by default.
  """
  @spec fn_with_timeout((() -> val), non_neg_integer()) :: (() -> val) when val: any()
  def fn_with_timeout(fun, timeout) do
    fn ->
      _ = :timer.exit_after(timeout, :kill)
      fun.()
    end
  end
end
