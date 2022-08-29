defmodule Screens.V2.CandidateGenerator.Widgets.CRDepartures do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.{CRDepartures, PreFare}
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.CRDepartures, as: CRDeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, OvernightDepartures}

  def departures_instances(
        config,
        fetch_departures_fn \\ &fetch_departures/2,
        now \\ DateTime.utc_now()
      )

  def departures_instances(
        %Screen{
          app_params: %PreFare{cr_departures: %CRDepartures{enabled: false}}
        },
        _,
        _
      ) do
    []
  end

  def departures_instances(
        %Screen{
          app_params: %PreFare{
            cr_departures:
              %CRDepartures{
                direction_to_destination: direction_to_destination,
                station: station,
                destination: destination
              } = cr_departures
          }
        } = config,
        fetch_departures_fn,
        now
      ) do
    case fetch_departures_fn.(direction_to_destination, station) do
      {:ok, departures_data} ->
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

      :error ->
        []
    end
  end

  def departures_instances(_, _, _), do: []

  defp fetch_departures(direction_to_destination, station) do
    opts = %{include_schedules: true}

    params = %{
      direction_id: direction_to_destination,
      route_ids: [
        "CR-Franklin",
        "CR-Needham",
        "CR-Providence"
      ],
      route_type: :rail,
      stop_ids: [station]
    }

    Departure.fetch(params, Keyword.new(opts))
  end
end
