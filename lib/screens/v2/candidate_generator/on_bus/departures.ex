defmodule Screens.V2.CandidateGenerator.Widgets.OnBus.Departures do
  @moduledoc false

  alias Screens.Report
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V2.Departure
  alias Screens.V2.ScreenData.QueryParams
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.Departures.NormalSection
  alias Screens.V2.WidgetInstance.{DeparturesNoData, DeparturesNoService}
  alias ScreensConfig.Screen

  import Screens.Inject

  @stop injected(Stop)
  @departure injected(Departure)

  @max_departure_results 3

  @type widget :: DeparturesNoData.t() | DeparturesNoService.t() | DeparturesWidget.t()

  @priority %{
    :subway => 1,
    :light_rail => 1,
    :bus => 2,
    :commuter_rail => 3,
    :ferry => 4
  }

  @spec departures_candidates(Screen.t(), QueryParams.t(), DateTime.t()) :: [widget()]
  def departures_candidates(config, %{stop_id: stop_id, route_id: route_id}, now) do
    route_id
    |> fetch_departures(stop_id)
    |> departures_widget(config, now)
  end

  def departures_candidates(config, _, _) do
    [%DeparturesNoData{screen: config}]
  end

  defp fetch_departures(route_id, stop_id) do
    fetch_params = %{:stop_ids => fetch_connecting_stops(stop_id)}
    fetch_opts = [include_schedules: false]

    with {:ok, departures} <- @departure.fetch(fetch_params, fetch_opts) do
      {:ok,
       departures
       |> filter_current_route(route_id)
       |> filter_duplicate_routes()
       |> sort_by_mode()}
    end
  end

  @spec fetch_connecting_stops(String.t()) :: nonempty_list(String.t())
  defp fetch_connecting_stops(stop_id) do
    case @stop.fetch(%{ids: [stop_id]}, true) do
      {:ok, stops} ->
        List.flatten([
          stop_id,
          Enum.map(stops, &child_stop_ids/1),
          Enum.map(stops, &connecting_stop_ids/1),
          Enum.map(stops, &parent_stop_ids/1)
        ])

      :error ->
        Report.warning("fetch_connecting_stops_error", stop_id: stop_id)
        [stop_id]
    end
  end

  @spec connecting_stop_ids(Stop.t()) :: [String.t()]
  defp connecting_stop_ids(%Stop{connecting_stops: stops}), do: Enum.map(stops, & &1.id)

  @spec child_stop_ids(Stop.t()) :: [String.t()]
  defp child_stop_ids(%Stop{child_stops: stops}) do
    stops
    |> Enum.filter(fn child -> child.location_type == 0 end)
    |> Enum.map(& &1.id)
  end

  @spec parent_stop_ids(Stop.t()) :: [String.t()]
  defp parent_stop_ids(%Stop{parent_station: nil}), do: []

  defp parent_stop_ids(%Stop{parent_station: stop = %Stop{id: id}}) do
    Enum.concat([[id], child_stop_ids(stop), connecting_stop_ids(stop)])
  end

  # Only return departures that are not from the bus's current route in either direction
  defp filter_current_route(departures, route_id) do
    Enum.filter(departures, &(&1.prediction.route.id != route_id))
  end

  defp filter_duplicate_routes(departures) do
    unique_departures =
      Enum.uniq_by(departures, fn dep ->
        {dep.prediction.route.line.id, Trip.representative_headsign(dep.prediction.trip)}
      end)

    if length(unique_departures) >= 3 do
      unique_departures
    else
      # If there are fewer than 3 unique connecting departures, then return at least 3.
      # Maintain sorting based on the original departure list sorting, which is currently by departure time.
      departure_indexes = departures |> Enum.with_index() |> Map.new()

      unique_departures
      |> Enum.concat(Enum.take(departures -- unique_departures, 3 - length(unique_departures)))
      |> Enum.sort_by(&Map.fetch!(departure_indexes, &1))
    end
  end

  defp sort_by_mode(departures) do
    Enum.sort_by(departures, &Map.get(@priority, &1.prediction.route.type))
  end

  @spec departures_widget(:error, Screen.t(), DateTime.t()) ::
          nonempty_list(DeparturesNoData.t())
  @spec departures_widget({:ok, []}, Screen.t(), DateTime.t()) ::
          nonempty_list(DeparturesNoService.t())
  @spec departures_widget({:ok, nonempty_list(Departure.t())}, Screen.t(), DateTime.t()) ::
          nonempty_list(DeparturesWidget.t())
  defp departures_widget(:error, config, _) do
    [%DeparturesNoData{screen: config}]
  end

  defp departures_widget({:ok, []}, config, _) do
    [%DeparturesNoService{screen: config}]
  end

  defp departures_widget({:ok, departure_data}, config, now) do
    [
      %DeparturesWidget{
        screen: config,
        sections: [
          %NormalSection{
            rows: Enum.take(departure_data, @max_departure_results),
            layout: %ScreensConfig.Departures.Layout{},
            header: %ScreensConfig.Departures.Header{title: "CONNECTIONS"}
          }
        ],
        now: now,
        slot_names: [:main_content]
      }
    ]
  end
end
