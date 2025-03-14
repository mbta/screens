defmodule Screens.V2.CandidateGenerator.Widgets.OnBus.Departures do
  @moduledoc false

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
    fetch_params = %{:stop_ids => [stop_id]}
    fetch_opts = [include_schedules: false]

    with {:ok, departures} <- departure_fetch_fn.(fetch_params, fetch_opts) do
      {:ok,
       departures
       |> filter_current_route(route_id)
       |> filter_duplicates()
       |> sort_by_mode()}
    end
  end

  # Only return departures that are not from the bus's current route in either direction
  defp filter_current_route(departures, route_id) do
    Enum.filter(departures, &(&1.prediction.route.id != route_id))
  end

  defp filter_duplicates(departures) do
    # TODO: What if there is only one route ID/direction in the departures at this stop? Should we still return two
    Enum.uniq_by(departures, fn dep ->
      {dep.prediction.route.id, dep.prediction.trip.direction_id}
    end)
  end

  defp sort_by_mode(departures) do
    # TODO: Compile time type checking?
    priority = %{
      :subway => 1,
      :light_rail => 1,
      :bus => 2,
      :commuter_rail => 3,
      :ferry => 4
    }

    Enum.sort(departures, fn a, b ->
      priority_a =
        Map.get(priority, a.prediction.route.type)

      priority_b =
        Map.get(priority, b.prediction.route.type)

      if priority_a == priority_b do
        a.prediction.arrival_time >= b.prediction.arrival_time
      else
        priority_a < priority_b
      end
    end)
  end

  @spec process_response({:error, any()}, Screen.t(), DateTime.t()) :: [DeparturesNoData]
  @spec process_response({:ok, []}, Screen.t(), DateTime.t()) :: [DeparturesNoService]
  @spec process_response({:ok, [Departure.t()]}, Screen.t(), DateTime.t()) :: [DeparturesWidget]
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
            rows: departure_data,
            layout: %ScreensConfig.V2.Departures.Layout{
              base: nil,
              include_later: false,
              max: @max_departure_results,
              min: 0
            },
            header: %ScreensConfig.V2.Departures.Header{
              arrow: nil,
              read_as: nil,
              title: nil
            }
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
