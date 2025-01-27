defmodule Screens.V2.CandidateGenerator.Widgets.CRDepartures do
  @moduledoc false

  alias Screens.Schedules.Schedule
  alias Screens.Util
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.CRDepartures, as: CRDeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, OvernightCRDepartures}
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.{CRDepartures, PreFare}

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
                pair_with_alert_widget: pair_with_alert_widget,
                station: station,
                destination: destination,
                header_pill: header_pill
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
                header_pill: header_pill,
                slot: get_slot(pair_with_alert_widget),
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
        "CR-Providence",
        "CR-Fitchburg"
      ],
      route_type: :rail,
      stop_ids: [station]
    }

    Departure.fetch(params, Keyword.new(opts))
  end

  defp fetch_last_schedule_tomorrow(direction_to_destination, station, now) do
    service_date_tomorrow = now |> Util.service_date() |> Date.add(1)

    params = %{
      direction_id: direction_to_destination,
      route_ids: [
        "CR-Franklin",
        "CR-Needham",
        "CR-Providence",
        "CR-Fitchburg"
      ],
      route_type: :rail,
      stop_ids: [station],
      sort: "-departure_time"
    }

    {:ok, schedules} = Schedule.fetch(params, service_date_tomorrow)
    List.first(schedules)
  end

  defp get_slot(false), do: [:main_content_left]
  defp get_slot(true), do: [:main_content_left, :full_body_right]
end
