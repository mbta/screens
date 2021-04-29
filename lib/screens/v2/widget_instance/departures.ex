defmodule Screens.V2.WidgetInstance.Departures do
  @moduledoc false

  alias Screens.Config.Dup.Override.FreeText
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures

  defstruct screen: nil,
            section_data: []

  @type normal_section :: %{
          type: :normal_section,
          departures: list(Departure.t())
        }

  @type notice_section :: %{
          type: :notice_section,
          icon: atom(),
          text: FreeText.t()
        }

  @type section :: normal_section | notice_section
  @type t :: %__MODULE__{
          screen: Screens.Config.Screen.t(),
          section_data: list(section)
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(%Departures{section_data: section_data}) do
      %{sections: Enum.map(section_data, &serialize_section/1)}
    end

    defp serialize_section(%{type: :notice_section} = section), do: section

    defp serialize_section(%{type: :normal_section, departures: departures}) do
      rows = group_departures(departures)
      %{type: :normal_section, rows: Enum.map(rows, &serialize_row/1)}
    end

    defp group_departures(departures) do
      departures
      |> Enum.chunk_by(fn d -> {Departure.route_id(d), Departure.headsign(d)} end)
      |> Enum.map(&make_row/1)
    end

    defp make_row([first_departure | _] = departure_list) do
      route_id = Departure.route_id(first_departure)
      headsign = Departure.headsign(first_departure)
      inline_alerts = first_departure |> Departure.alerts() |> Enum.filter(&alert_is_inline?/1)

      %{
        route_id: route_id,
        headsign: headsign,
        inline_alerts: inline_alerts,
        departures: departure_list
      }
    end

    defp alert_is_inline?(%{effect: :delay}), do: true
    defp alert_is_inline?(_), do: false

    defp serialize_row(%{
           route_id: route_id,
           headsign: headsign,
           inline_alerts: inline_alerts,
           departures: departures
         }) do
      %{
        route: serialize_route(route_id),
        headsign: serialize_headsign(headsign),
        times_with_crowding: serialize_times_with_crowding(departures),
        inline_alerts: serialize_inline_alerts(inline_alerts)
      }
    end

    defp serialize_route(route_id) do
      route =
        cond do
          String.starts_with?(route_id, "CR-") ->
            %{type: :icon, icon: :rail}

          String.starts_with?(route_id, "Boat-") ->
            %{type: :icon, icon: :boat}

          String.contains?(route_id, "/") ->
            [part1, part2] = String.split(route_id, "/")
            %{type: :slashed, part1: part1, part2: part2}

          true ->
            %{type: :text, text: route_id}
        end

      Map.merge(route, %{color: get_color_for_route(route_id)})
    end

    defp get_color_for_route("Red"), do: :red
    defp get_color_for_route("Mattapan"), do: :red
    defp get_color_for_route("Orange"), do: :orange
    defp get_color_for_route("Blue"), do: :blue

    defp get_color_for_route(route_id)
         when route_id in ["Green-B", "Green-C", "Green-D", "Green-E"],
         do: :green

    defp get_color_for_route(route_id)
         when route_id in ["741", "742", "743", "746", "749", "751"],
         do: :silver

    defp get_color_for_route(route_id) do
      cond do
        String.starts_with?(route_id, "CR-") -> :purple
        String.starts_with?(route_id, "Boat-") -> :teal
        true -> :yellow
      end
    end

    defp serialize_headsign(headsign) do
      via_pattern = ~r/(.+) (via .+)/
      paren_pattern = ~r/(.+) (\(.+)/

      [headsign, variation] =
        cond do
          String.match?(headsign, via_pattern) ->
            via_pattern |> Regex.run(headsign) |> Enum.drop(1)

          String.match?(headsign, paren_pattern) ->
            paren_pattern |> Regex.run(headsign) |> Enum.drop(1)

          true ->
            [headsign, nil]
        end

      %{headsign: headsign, variation: variation}
    end

    defp serialize_times_with_crowding(departures) do
      Enum.map(departures, &serialize_time_with_crowding/1)
    end

    defp serialize_time_with_crowding(departure) do
      %{time: serialize_time(departure), crowding: serialize_crowding(departure)}
    end

    # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
    defp serialize_time(departure) do
      departure_time = Departure.time(departure)
      vehicle_status = Departure.vehicle_status(departure)
      stop_type = Departure.stop_type(departure)
      route_type = Departure.route_type(departure)

      now = DateTime.utc_now()
      second_diff = DateTime.diff(departure_time, now)
      minute_diff = div(second_diff, 60)

      cond do
        vehicle_status == :stopped_at and second_diff < 90 ->
          %{type: :text, text: "BRD"}

        second_diff < 30 and stop_type == :first_stop ->
          %{type: :text, text: "BRD"}

        second_diff < 30 ->
          %{type: :text, text: "ARR"}

        minute_diff < 60 and route_type not in [2, 4] ->
          %{type: :minutes, minutes: minute_diff}

        true ->
          {:ok, local_time} = DateTime.shift_zone(departure_time, "America/New_York")
          hour = 1 + rem(local_time.hour - 1, 12)
          minute = local_time.minute
          am_pm = if local_time.hour >= 12, do: :pm, else: :am
          %{type: :timestamp, hour: hour, minute: minute, am_pm: am_pm}
      end
    end

    defp serialize_crowding(departure) do
      Departure.crowding_level(departure)
    end

    defp serialize_inline_alerts(inline_alerts) do
      Enum.map(inline_alerts, &serialize_inline_alert/1)
    end

    defp serialize_inline_alert(%{effect: :delay, severity: severity}) do
      {delay_description, delay_minutes} =
        cond do
          severity < 3 -> {"up to", 10}
          severity > 9 -> {"more than", 60}
          severity >= 8 -> {"more than", 30 * (severity - 7)}
          true -> {"up to", 5 * (severity - 1)}
        end

      delay_text = ["Delays #{delay_description}", %{format: :bold, text: "#{delay_minutes}m"}]
      %{icon: :clock, text: delay_text, color: :black}
    end

    def slot_names(_instance), do: [:main_content]

    def widget_type(_instance), do: :departures
  end
end
