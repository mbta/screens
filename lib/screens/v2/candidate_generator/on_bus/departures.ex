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

  @spec departures_instances(Screen.t(), String.t(), String.t(), options()) :: widget()
  def departures_instances(config, route_id, stop_id, options \\ []) do
    departures =
      fetch_departures(
        route_id,
        stop_id,
        Keyword.get(options, :departure_fetch_fn, &Departure.fetch/2)
      )

    case departures do
      {:error, _} ->
        [%DeparturesNoData{screen: config, show_alternatives?: true}]

      {:ok, []} ->
        [%DeparturesNoService{screen: config}]

      {:ok, departure_data} ->
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
            now: Keyword.get(options, :now, DateTime.utc_now()),
            slot_names: [:main_content]
          }
        ]
    end
  end

  defp fetch_departures(route_id, stop_id, departure_fetch_fn) do
    fetch_params = %{:stop_ids => [stop_id]}
    fetch_opts = [include_schedules: false]

    is_bidirectional = true

    with {:ok, departures} <- departure_fetch_fn.(fetch_params, fetch_opts) do
      {:ok,
       departures
       |> filter_current_route(route_id)}
    end
  end

  # Only return departures that are not from the bus's current route in either direction
  defp filter_current_route(departures, route_id) do
    Enum.filter(departures, &(&1.prediction.trip.route_id != route_id))
  end
end
