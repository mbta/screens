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
        now \\ DateTime.utc_now(),
        fetch_departures_fn \\ &fetch_departures/3
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
        now,
        fetch_departures_fn
      ) do
    case fetch_departures_fn.(direction_to_destination, station, now) do
      {:ok, departures_data} ->
        inbound_outbound =
          if direction_to_destination == 0 do
            "outbound"
          else
            "inbound"
          end

        # The Overnight and NoData widgets may not be relevant here
        departures_instance =
          cond do
            departures_data == :error ->
              %DeparturesNoData{screen: config, show_alternatives?: true}

            Enum.empty?(departures_data) ->
              last_schedule_tomorrow =
                fetch_last_schedule_tomorrow(direction_to_destination, station, now)

              %OvernightCRDepartures{
                destination: destination,
                direction_to_destination: inbound_outbound,
                last_tomorrow_schedule: last_schedule_tomorrow,
                priority: cr_departures.priority,
                now: now
              }

            true ->
              %CRDeparturesWidget{
                config: cr_departures,
                departures_data: departures_data,
                destination: destination,
                direction_to_destination: inbound_outbound,
                now: now
              }
          end

        [departures_instance]

      :error ->
        []
    end
  end

  def departures_instances(_, _, _), do: []

  defp fetch_departures(direction_to_destination, station, now) do
    opts = %{include_schedules: true, now: now}

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
    # Any time between midnight and 3AM should be considered part of yesterday's service day.
    service_datetime =
      now |> DateTime.shift_zone!("America/New_York") |> DateTime.add(-3 * 60 * 60, :second)

    next_service_day =
      service_datetime |> DateTime.add(60 * 60 * 24, :second) |> Timex.format!("{YYYY}-{0M}-{0D}")

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

    {:ok, schedules} = Schedule.fetch(params, next_service_day)
    List.first(schedules)
  end
end
