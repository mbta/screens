defmodule Screens.V2.CandidateGenerator.Widgets.OnBus.Departures do
  @moduledoc false

  alias Screens.Stops.Stop
  alias Screens.V2.Departure
  alias Screens.V2.ScreenData.QueryParams
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.Departures.NormalSection
  alias Screens.V2.WidgetInstance.{DeparturesNoData, DeparturesNoService}
  alias ScreensConfig.Screen

  @max_departure_results 2

  @type widget ::
          DeparturesNoData.t() | DeparturesNoService.t() | DeparturesWidget.t()
  @type options :: [
          departure_fetch_fn: Departure.fetch(),
          now: DateTime.t()
        ]

  @spec departures_candidate(Screen.t(), QueryParams.t(), options()) :: [widget()]
  def departures_candidate(config, query_params, options \\ [])

  def departures_candidate(
        config,
        %{stop_id: stop_id, route_id: route_id},
        options
      ) do
    now = Keyword.get(options, :now, DateTime.utc_now())
    fetch_fn = Keyword.get(options, :departure_fetch_fn, &Departure.fetch/2)

    route_id
    |> fetch_departures(stop_id, fetch_fn)
    |> process_response(config, now)
  end

  def departures_candidate(config, _query_params, _options) do
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

  defp fetch_connecting_stops(stop_id) do
    {:ok, stops} = Stop.fetch_connecting(%{ids: [stop_id]})
    Enum.map(stops, &stop_id(&1))
  end

  defp stop_id(stop), do: stop.id

  # Only return departures that are not from the bus's current route in either direction
  defp filter_current_route(departures, route_id) do
    Enum.filter(departures, &(&1.prediction.route.id != route_id))
  end

  @spec process_response({:error, any()}, Screen.t(), DateTime.t()) ::
          nonempty_list(DeparturesNoData.t())
  @spec process_response({:ok, []}, Screen.t(), DateTime.t()) ::
          nonempty_list(DeparturesNoService.t())
  @spec process_response({:ok, [Departure.t()]}, Screen.t(), DateTime.t()) ::
          nonempty_list(DeparturesWidget.t())
  defp process_response({:error, _}, config, _) do
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
    [%DeparturesNoData{screen: config, show_alternatives?: true}]
  end
end
