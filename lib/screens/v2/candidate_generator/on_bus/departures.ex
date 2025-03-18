defmodule Screens.V2.CandidateGenerator.Widgets.OnBus.Departures do
  @moduledoc false

  alias Screens.Report
  alias Screens.Stops.Stop
  alias Screens.V2.Departure
  alias Screens.V2.ScreenData.QueryParams
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.Departures.NormalSection
  alias Screens.V2.WidgetInstance.{DeparturesNoData, DeparturesNoService}
  alias ScreensConfig.Screen

  import Screens.Inject

  @stop injected(Stop)

  @max_departure_results 3

  @type widget :: DeparturesNoData.t() | DeparturesNoService.t() | DeparturesWidget.t()

  @spec departures_candidate(Screen.t(), QueryParams.t(), DateTime.t(), Departure.fetch()) :: [
          widget()
        ]
  def departures_candidate(config, %{stop_id: stop_id, route_id: route_id}, now, fetch_fn) do
    route_id
    |> fetch_departures(stop_id, fetch_fn)
    |> process_response(config, now)
  end

  def departures_candidate(config, _, _, _fetch_fn) do
    build_no_data_widget(config)
  end

  defp fetch_departures(route_id, stop_id, departure_fetch_fn) do
    fetch_params = %{:stop_ids => fetch_connecting_stops(stop_id)}
    fetch_opts = [include_schedules: false]

    with {:ok, departures} <- departure_fetch_fn.(fetch_params, fetch_opts) do
      {:ok,
       departures
       |> filter_current_route(route_id)}
    end
  end

  @spec fetch_connecting_stops(String.t()) :: nonempty_list(String.t())
  defp fetch_connecting_stops(stop_id) do
    case @stop.fetch(%{ids: [stop_id], location_types: [0, 1]}, true) do
      {:ok, stops} ->
        Enum.flat_map(stops, &parent_stop_ids/1) ++
          Enum.flat_map(stops, &connecting_stop_ids/1) ++
          Enum.flat_map(stops, &child_stop_ids/1) ++
          [stop_id]

      :error ->
        Report.warning("fetch_connecting_stops_error", stop_id: stop_id)
        [stop_id]
    end
  end

  @spec connecting_stop_ids(Stop) :: [String.t()]
  defp connecting_stop_ids(stop) do
    stop |> Map.get(:connecting_stops) |> Enum.map(&stop_id(&1))
  end

  @spec connecting_stop_ids(Stop) :: [String.t()]
  defp child_stop_ids(stop) do
    stop
    |> Map.get(:child_stops)
    |> Enum.map(&stop_id(&1))
  end

  @spec connecting_stop_ids(Stop) :: [String.t()]
  defp parent_stop_ids(stop) do
    parent_station =
      stop
      |> Map.get(:parent_station)

    case parent_station do
      nil ->
        []

      # If a parent_station has any connecting stops, we also get those IDs
      _ ->
        parent_station
        |> Enum.filter(fn stop -> stop.location_type == 0 end)
        |> Enum.map(&stop_id(&1))
        |> Enum.concat(&connecting_stop_ids(&1))
    end
  end

  defp stop_id(stop), do: stop.id

  # Only return departures that are not from the bus's current route in either direction
  defp filter_current_route(departures, route_id) do
    Enum.filter(departures, &(&1.prediction.route.id != route_id))
  end

  @spec process_response(:error, Screen.t(), DateTime.t()) ::
          nonempty_list(DeparturesNoData.t())
  @spec process_response({:ok, []}, Screen.t(), DateTime.t()) ::
          nonempty_list(DeparturesNoService.t())
  @spec process_response({:ok, nonempty_list(Departure.t())}, Screen.t(), DateTime.t()) ::
          nonempty_list(DeparturesWidget.t())
  defp process_response(:error, config, _) do
    build_no_data_widget(config)
  end

  defp process_response({:ok, []}, config, _) do
    [%DeparturesNoService{screen: config}]
  end

  defp process_response({:ok, departure_data}, config, now) do
    [
      %DeparturesWidget{
        screen: config,
        sections: [
          %NormalSection{
            rows: Enum.take(departure_data, @max_departure_results),
            layout: %ScreensConfig.V2.Departures.Layout{},
            header: %ScreensConfig.V2.Departures.Header{}
          }
        ],
        now: now,
        slot_names: [:main_content]
      }
    ]
  end

  defp build_no_data_widget(config) do
    [%DeparturesNoData{screen: config}]
  end
end
