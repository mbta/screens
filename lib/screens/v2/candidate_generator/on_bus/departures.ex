defmodule Screens.V2.CandidateGenerator.Widgets.OnBus.Departures do
  @moduledoc false

  alias Screens.V2.Departure
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

  @spec departures_candidate(Screen.t(), String.t(), String.t(), options()) :: [widget()]
  def departures_candidate(config, route_id, stop_id, options \\ []) do
    route_id
    |> fetch_departures(
      stop_id,
      Keyword.get(options, :departure_fetch_fn, &Departure.fetch/2)
    )
    |> process_response(config, Keyword.get(options, :now, DateTime.utc_now()))
  end

  defp fetch_departures(route_id, stop_id, departure_fetch_fn) do
    fetch_params = %{:stop_ids => [stop_id]}
    fetch_opts = [include_schedules: false]

    with {:ok, departures} <- departure_fetch_fn.(fetch_params, fetch_opts) do
      {:ok,
       departures
       |> filter_current_route(route_id)}
    end
  end

  # Only return departures that are not from the bus's current route in either direction
  defp filter_current_route(departures, route_id) do
    Enum.filter(departures, &(&1.prediction.route.id != route_id))
  end

  @spec process_response({:error, any()}, Screen.t(), DateTime.t()) :: [DeparturesNoData]
  @spec process_response({:ok, []}, Screen.t(), DateTime.t()) :: [DeparturesNoService]
  @spec process_response({:ok, [Departure.t()]}, Screen.t(), DateTime.t()) :: [DeparturesWidget]
  defp process_response({:error, _}, config, _) do
    [%DeparturesNoData{screen: config, show_alternatives?: true}]
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
end
