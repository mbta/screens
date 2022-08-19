defmodule Screens.V2.CandidateGenerator.Widgets.CRDepartures do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.{CRDepartures, PreFare}
  alias Screens.Stops.Stop
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.CRDepartures, as: CRDeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, OvernightDepartures}

  def departures_instances(
        config,
        fetch_departures_fn \\ &fetch_departures/2,
        fetch_stop_name_fn \\ &Stop.fetch_stop_name/1,
        now \\ DateTime.utc_now()
      )

  def departures_instances(
        %Screen{app_params: %app{cr_departures: %CRDepartures{} = cr_departures}} = config,
        fetch_departures_fn,
        fetch_stop_name_fn,
        now
      )
      when app in [PreFare] do
    opts = %{include_schedules: true}

    params = %{
      direction_id: cr_departures.direction_to_destination,
      route_type: :rail,
      stop_ids: [cr_departures.station]
    }

    destination = fetch_stop_name_fn.(cr_departures.destination)

    {:ok, departures_data} = fetch_departures_fn.(opts, params)

    # The Overnight and NoData widgets may not be relevant here
    departures_instance =
      cond do
        departures_data == :error ->
          %DeparturesNoData{screen: config, show_alternatives?: true}

        departures_data == :overnight ->
          %OvernightDepartures{}

        true ->
          %CRDeparturesWidget{
            config: cr_departures,
            departures_data: departures_data,
            destination: destination,
            now: now
          }
      end

    [departures_instance]
  end

  def departures_instances(_, _, _, _), do: []

  defp fetch_departures(opts, params) do
    Departure.fetch(params, Keyword.new(opts))
  end
end
