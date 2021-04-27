defmodule Screens.V2.WidgetInstance.Departures do
  @moduledoc false

  alias Screens.Config.Dup.Override.FreeText
  alias Screens.Departures.Departure
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
      |> Enum.chunk_by(fn %Departure{route_id: route_id, destination: destination} ->
        {route_id, destination}
      end)
      |> Enum.map(&make_row/1)
    end

    defp make_row([first_departure | _] = departure_list) do
      %Departure{route_id: route_id, destination: destination, inline_badges: inline_badges} =
        first_departure

      times_with_crowding =
        Enum.map(departure_list, fn %Departure{time: time, crowding_level: crowding_level} ->
          {time, crowding_level}
        end)

      %{
        route_id: route_id,
        destination: destination,
        times_with_crowding: times_with_crowding,
        inline_badges: inline_badges
      }
    end

    defp serialize_row(%{
           route_id: route_id,
           destination: destination,
           times_with_crowding: times_with_crowding,
           inline_badges: inline_badges
         }) do
      %{
        route: serialize_route(route_id),
        destination: serialize_destination(destination),
        times_with_crowding: serialize_times(times_with_crowding),
        inline_alerts: serialize_inline_alerts(inline_badges)
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

    defp serialize_destination(destination) do
      via_pattern = ~r/(.+) (via .+)/
      paren_pattern = ~r/(.+) (\(.+)/

      [headsign, variation] =
        cond do
          String.match?(destination, via_pattern) ->
            via_pattern |> Regex.run(destination) |> Enum.drop(1)

          String.match?(destination, paren_pattern) ->
            paren_pattern |> Regex.run(destination) |> Enum.drop(1)

          true ->
            [destination, nil]
        end

      %{headsign: headsign, variation: variation}
    end

    defp serialize_times(times_with_crowding) do
      Enum.map(times_with_crowding, &serialize_time_with_crowding/1)
    end

    defp serialize_time_with_crowding({time, crowding_level}) do
      {serialize_time(time), crowding_level}
    end

    defp serialize_time(departure_time) do
      now = DateTime.utc_now()
      second_diff = DateTime.diff(now, departure_time)
      minute_diff = div(second_diff, 60)

      cond do
        second_diff < 30 ->
          %{type: :text, text: "ARR"}

        minute_diff < 60 ->
          %{type: :minutes, minutes: minute_diff}

        true ->
          {:ok, local_time} = DateTime.shift_zone(departure_time, "America/New_York")
          hour = 1 + rem(local_time.hour - 1, 12)
          minute = local_time.minute
          am_pm = if local_time.hour >= 12, do: :pm, else: :am
          %{type: :timestamp, hour: hour, minute: minute, am_pm: am_pm}
      end
    end

    defp serialize_inline_alerts(inline_alerts) do
      Enum.map(inline_alerts, &serialize_inline_alert/1)
    end

    defp serialize_inline_alert(%{type: :delay, severity: severity}) do
      {delay_minutes, delay_description} =
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
