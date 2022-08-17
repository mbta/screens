defmodule Screens.V2.CandidateGenerator.Widgets.CRDepartures do
  @moduledoc """

  """

  alias Screens.Config.Screen
  alias Screens.Config.V2.{CRDepartures, PreFare}
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.CRDepartures, as: CRDeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, OvernightDepartures}

  def departures_instances(
        %Screen{app_params: %app{cr_departures: %CRDepartures{} = cr_departures}} = config,
        fetch_departures_fn \\ &fetch_departures/2
      )
      when app in [PreFare] do
    # Main departures widaget has mode_disabled option. Need for CR departures?
    opts = %{include_schedules: true}

    params = %{
      direction_id: cr_departures.direction_to_destination,
      route_type: :rail,
      stop_ids: [cr_departures.station]
    }

    {:ok, departures_data} = fetch_departures_fn.(opts, params)

    # TODO: are the Overnight and NoData widgets relevant?
    departures_instance =
      cond do
        departures_data == :error ->
          %DeparturesNoData{screen: config, show_alternatives?: true}

        departures_data == :overnight ->
          %OvernightDepartures{}

        true ->
          %CRDeparturesWidget{config: cr_departures, departures_data: departures_data}
      end

    [departures_instance]
  end

  defp fetch_departures(opts, params) do
    Departure.fetch(params, Keyword.new(opts))
  end
end
