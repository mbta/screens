defmodule Screens.V2.CandidateGenerator.Widgets.CRDepartures do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.{CRDepartures, PreFare}
  alias Screens.Schedules.Schedule
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.CRDepartures, as: CRDeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, OvernightCRDepartures}

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
                destination: destination,
                overnight_weekday_asset_path: overnight_weekday_asset_path,
                overnight_weekend_asset_path: overnight_weekend_asset_path
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

            Enum.empty?(departures_data) ->
              last_schedule_tomorrow =
                fetch_last_schedule_tomorrow(direction_to_destination, station, now)

              %OvernightCRDepartures{
                screen: config,
                direction_to_destination: direction_to_destination,
                last_tomorrow_schedule: last_schedule_tomorrow,
                priority: cr_departures.priority,
                now: now
              }

            true ->
              %CRDeparturesWidget{
                config: cr_departures,
                departures_data: departures_data,
                destination: destination,
                now: now,
                overnight_weekday_asset_path: overnight_weekday_asset_path,
                overnight_weekend_asset_path: overnight_weekend_asset_path
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

  defp fetch_last_schedule_tomorrow(direction_to_destination, station, now) do
    tomorrow =
      now
      |> Timex.to_datetime("America/New_York")
      |> Timex.shift(days: 1)
      |> Timex.format!("{YYYY}-{0M}-{0D}")

    params = %{
      direction_id: direction_to_destination,
      route_ids: [
        "CR-Franklin",
        "CR-Needham",
        "CR-Providence"
      ],
      route_type: :rail,
      stop_ids: [station],
      sort: "-departure_time"
    }

    {:ok, schedules} = Schedule.fetch(params, tomorrow)
    List.first(schedules)
  end
end
