defmodule Screens.TestSupport.DisruptionDiagramLocalizedAlert do
  @moduledoc """
  Provides a function that generates localized alerts intended for
  use with disruption diagrams.

  Only the struct fields required by disruption diagrams are populated,
  so this might not work for testing other code related to localized alerts.
  """

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.Stops.Stop

  @doc """
  Creates a localized alert with the given effect, located at the given home station.

  When creating a station closure alert, `informed_stops` should be a list of stop IDs.

  When creating a shuttle or suspension, `informed_stops` should be a tuple of `{first_stop_id, last_stop_id}`.
  Keep in mind that stop order will be based on sequences for direction_id=0.
  For example, a shuttle from DTX to Back Bay must be entered as
  `{"place-dwnxg", "place-bbsta"}`, not `{"place-bbsta", "place-dwnxg"}`.

  Options:
  - :informed_routes
    - If `:per_stop`, the informed route(s) for each stop will be all subway routes that serve it.
      When a GL trunk stop is disrupted, it will always get informed entities for all routes that serve it,
      even if the alert later goes down one particular branch.
    - If `:overall`, the informed route(s) will be whichever fully contain all informed stops.
      For alerts that inform any GL branch stops, this means the only informed route will be that branch.
      This is the default AlertsUI behavior.
    - Defaults to `:overall`.
  """
  def make_localized_alert(effect, line, home_station_id, informed_stops, opts \\ [])

  def make_localized_alert(:station_closure, line, home_station_id, stop_ids, opts)
      when is_list(stop_ids) do
    alert = %Alert{
      effect: :station_closure,
      informed_entities:
        ies(line, stop_ids, Keyword.get(opts, :informed_routes, :overall), home_station_id)
    }

    %{alert: alert, location_context: make_location_context(home_station_id)}
  end

  def make_localized_alert(continuous, line, home_station_id, {_first, _last} = stop_range, opts)
      when continuous in [:shuttle, :suspension] do
    alert = %Alert{
      effect: continuous,
      informed_entities:
        ies(
          line,
          stop_range_to_list(stop_range),
          Keyword.get(opts, :informed_routes, :overall),
          home_station_id
        )
    }

    %{alert: alert, location_context: make_location_context(home_station_id)}
  end

  defp make_location_context(home_station_id) do
    %LocationContext{
      home_stop: home_station_id,
      tagged_stop_sequences: tagged_stop_sequences_through_station(home_station_id)
    }
  end

  defp ies(:green, stop_ids, :per_stop, _home_stop) do
    for stop_id <- stop_ids,
        "Green" <> _ = route_id <- subway_routes_at_station(stop_id),
        do: %{route: route_id, stop: stop_id}
  end

  defp ies(:green, stop_ids, :overall, home_stop) do
    route_ids =
      [home_stop | stop_ids]
      |> MapSet.new()
      |> routes_containing_all()
      |> Enum.filter(&match?("Green" <> _, &1))

    result =
      for stop_id <- stop_ids,
          route_id <- route_ids,
          do: %{route: route_id, stop: stop_id}

    if result == [] do
      raise "No stop sequence contains all informed stops + home stop"
    else
      result
    end
  end

  defp ies(line, stop_ids, _, _) when line in [:blue, :orange, :red] do
    route_id =
      line
      |> Atom.to_string()
      |> String.capitalize()

    for stop_id <- stop_ids, do: %{route: route_id, stop: stop_id}
  end

  defp stop_range_to_list({first_station_id, last_station_id}) do
    endpoints_set = MapSet.new([first_station_id, last_station_id])

    Stop.get_all_routes_stop_sequence()
    |> Enum.find_value(fn
      {_route_id, labeled_sequences} ->
        Enum.find_value(labeled_sequences, fn labeled_sequence ->
          stop_sequence = Enum.map(labeled_sequence, &elem(&1, 0))
          if MapSet.subset?(endpoints_set, MapSet.new(stop_sequence)), do: stop_sequence
        end)
    end)
    |> case do
      nil ->
        raise "No stop sequence contains both of the two given stations: {#{first_station_id}, #{last_station_id}}"

      sequence ->
        index_of_first = Enum.find_index(sequence, &(&1 == first_station_id))
        index_of_last = Enum.find_index(sequence, &(&1 == last_station_id))

        Enum.slice(sequence, index_of_first..index_of_last//1)
    end
  end

  # Returns IDs of the subway/light rail route(s) that serve the given station,
  # using our hardcoded stop sequences rather than API calls.
  defp subway_routes_at_station(parent_station_id) do
    Stop.get_all_routes_stop_sequence()
    |> Enum.filter(fn
      # Green isn't a real route ID, ignore it.
      {"Green", _} ->
        false

      {_route_id, labeled_sequences} ->
        stop_sequences =
          Enum.map(labeled_sequences, fn labeled_sequence ->
            Enum.map(labeled_sequence, &elem(&1, 0))
          end)

        Enum.any?(stop_sequences, &(parent_station_id in &1))
    end)
    |> Enum.map(fn {route_id, _stop_sequences} -> route_id end)
  end

  # Returns a %{route => stop_sequences} map for all sequences that that contain the given subway/light rail station.
  defp tagged_stop_sequences_through_station(parent_station_id) do
    Stop.get_all_routes_stop_sequence()
    |> Enum.flat_map(fn
      # Green isn't a real route ID, ignore it.
      {"Green", _} ->
        []

      {route_id, labeled_sequences} ->
        matching_stop_sequences =
          Enum.flat_map(labeled_sequences, fn labeled_sequence ->
            stop_sequence = Enum.map(labeled_sequence, &elem(&1, 0))
            if parent_station_id in stop_sequence, do: [stop_sequence], else: []
          end)

        if matching_stop_sequences != [], do: [{route_id, matching_stop_sequences}], else: []
    end)
    |> Map.new()
  end

  # Returns IDs of the route(s) whose stop sequence(s) contain all of the given stops.
  defp routes_containing_all(parent_station_ids) do
    Stop.get_all_routes_stop_sequence()
    |> Enum.filter(fn
      # Green isn't a real route ID, ignore it.
      {"Green", _} ->
        false

      {_route_id, labeled_sequences} ->
        Enum.any?(labeled_sequences, fn labeled_sequence ->
          stops = MapSet.new(labeled_sequence, &elem(&1, 0))
          MapSet.subset?(parent_station_ids, stops)
        end)
    end)
    |> Enum.map(fn {route_id, _} -> route_id end)
  end
end
