defmodule Screens.V2.WidgetInstance.Departures do
  @moduledoc false

  alias Screens.Config.Dup.Override.FreeText
  alias Screens.Config.Screen
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
          icon: atom() | nil,
          text: FreeText.t()
        }

  @type section :: normal_section | notice_section
  @type t :: %__MODULE__{
          screen: Screen.t(),
          section_data: list(section)
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(%Departures{section_data: section_data, screen: screen}) do
      %{sections: Enum.map(section_data, &Departures.serialize_section(&1, screen))}
    end

    def slot_names(_instance), do: [:main_content]

    def widget_type(_instance), do: :departures
  end

  def serialize_section(%{type: :notice_section, icon: icon, text: text}, _screen) do
    %{type: :notice_section, icon: icon, text: FreeText.to_json(text)}
  end

  def serialize_section(%{type: :normal_section, departures: departures}, screen) do
    rows = group_departures(departures)
    %{type: :normal_section, rows: Enum.map(rows, &serialize_row(&1, screen))}
  end

  def group_departures(departures) do
    Enum.chunk_by(departures, fn d -> {Departure.route_id(d), Departure.headsign(d)} end)
  end

  defp serialize_row(departures, screen) do
    departure_id_string =
      departures
      |> Enum.map(&Departure.id/1)
      |> Enum.sort()
      |> Enum.join("")

    row_id = :md5 |> :crypto.hash(departure_id_string) |> Base.encode64()

    %{
      id: row_id,
      route: serialize_route(departures),
      headsign: serialize_headsign(departures),
      times_with_crowding: serialize_times_with_crowding(departures, screen),
      inline_alerts: serialize_inline_alerts(departures)
    }
  end

  def serialize_route([first_departure | _]) do
    route_id = Departure.route_id(first_departure)
    route_name = Departure.route_name(first_departure)
    route_type = Departure.route_type(first_departure)
    track_number = Departure.track_number(first_departure)

    route =
      cond do
        not is_nil(track_number) ->
          %{type: :text, text: "TR#{track_number}"}

        route_type == :rail ->
          %{type: :icon, icon: :rail}

        route_type == :ferry ->
          %{type: :icon, icon: :boat}

        String.contains?(route_name, "/") ->
          [part1, part2] = String.split(route_name, "/")
          %{type: :slashed, part1: part1, part2: part2}

        true ->
          %{type: :text, text: get_text_for_route(route_id, route_name)}
      end

    Map.merge(route, %{color: get_color_for_route(route_id, route_type)})
  end

  defp get_text_for_route("Red", _), do: "RL"
  defp get_text_for_route("Mattapan", _), do: "M"
  defp get_text_for_route("Orange", _), do: "OL"
  defp get_text_for_route("Blue", _), do: "BL"
  defp get_text_for_route("Green-B", _), do: "GL"
  defp get_text_for_route("Green-C", _), do: "GL"
  defp get_text_for_route("Green-D", _), do: "GL"
  defp get_text_for_route("Green-E", _), do: "GL"
  defp get_text_for_route(_, route_name), do: route_name

  defp get_color_for_route("Red", _), do: :red
  defp get_color_for_route("Mattapan", _), do: :red
  defp get_color_for_route("Orange", _), do: :orange
  defp get_color_for_route("Blue", _), do: :blue

  defp get_color_for_route(route_id, _)
       when route_id in ["Green-B", "Green-C", "Green-D", "Green-E"],
       do: :green

  defp get_color_for_route(route_id, _)
       when route_id in ["741", "742", "743", "746", "749", "751"],
       do: :silver

  defp get_color_for_route(_, :rail), do: :purple
  defp get_color_for_route(_, :ferry), do: :teal
  defp get_color_for_route(_, _), do: :yellow

  def serialize_headsign([first_departure | _]) do
    headsign = Departure.headsign(first_departure)

    via_pattern = ~r/(.+) (via .+)/
    paren_pattern = ~r/(.+) (\(.+)/

    [headsign, variation] =
      cond do
        String.match?(headsign, via_pattern) ->
          Regex.run(via_pattern, headsign, capture: :all_but_first)

        String.match?(headsign, paren_pattern) ->
          Regex.run(paren_pattern, headsign, capture: :all_but_first)

        true ->
          [headsign, nil]
      end

    %{headsign: headsign, variation: variation}
  end

  def serialize_times_with_crowding(departures, screen, now \\ DateTime.utc_now()) do
    Enum.map(departures, &serialize_time_with_crowding(&1, screen, now))
  end

  defp serialize_time_with_crowding(departure, screen, now) do
    serialized_time =
      case Departure.route_type(departure) do
        :rail -> serialize_time_with_schedule(departure, screen, now)
        _ -> serialize_time(departure, screen, now)
      end

    Map.merge(serialized_time, %{
      id: Departure.id(departure),
      crowding: serialize_crowding(departure)
    })
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp serialize_time(departure, %Screen{app_id: app_id}, now)
       when app_id in [:bus_eink_v2, :gl_eink_v2] do
    departure_time = Departure.time(departure)

    second_diff = DateTime.diff(departure_time, now)
    minute_diff = 1 + div(second_diff - 1, 60)

    time =
      cond do
        second_diff < 60 ->
          %{type: :text, text: "Now"}

        minute_diff < 60 ->
          %{type: :minutes, minutes: minute_diff}

        true ->
          serialize_timestamp(departure_time)
      end

    %{time: time}
  end

  defp serialize_time(departure, _screen, now) do
    departure_time = Departure.time(departure)
    vehicle_status = Departure.vehicle_status(departure)
    stop_type = Departure.stop_type(departure)
    route_type = Departure.route_type(departure)

    second_diff = DateTime.diff(departure_time, now)
    minute_diff = div(second_diff, 60)

    time =
      cond do
        vehicle_status == :stopped_at and second_diff < 90 ->
          %{type: :text, text: "BRD"}

        second_diff < 30 and stop_type == :first_stop ->
          %{type: :text, text: "BRD"}

        second_diff < 30 ->
          %{type: :text, text: "ARR"}

        minute_diff < 60 and route_type not in [:rail, :ferry] ->
          %{type: :minutes, minutes: minute_diff}

        true ->
          serialize_timestamp(departure_time)
      end

    %{time: time}
  end

  defp serialize_time_with_schedule(departure, screen, now) do
    %{time: serialized_time} = serialize_time(departure, screen, now)

    scheduled_time = Departure.scheduled_time(departure)

    if is_nil(scheduled_time) do
      %{time: serialized_time}
    else
      serialized_scheduled_time = serialize_timestamp(scheduled_time)

      case serialized_time do
        %{type: :text} ->
          %{time: serialized_time}

        ^serialized_scheduled_time ->
          %{time: serialized_time}

        _ ->
          %{time: serialized_time, scheduled_time: serialized_scheduled_time}
      end
    end
  end

  defp serialize_timestamp(departure_time) do
    {:ok, local_time} = DateTime.shift_zone(departure_time, "America/New_York")
    hour = 1 + Integer.mod(local_time.hour - 1, 12)
    minute = local_time.minute
    am_pm = if local_time.hour >= 12, do: :pm, else: :am
    %{type: :timestamp, hour: hour, minute: minute, am_pm: am_pm}
  end

  defp serialize_crowding(departure) do
    Departure.crowding_level(departure)
  end

  def serialize_inline_alerts([first_departure | _]) do
    first_departure
    |> Departure.alerts()
    |> Enum.filter(&alert_is_inline?/1)
    |> Enum.map(&serialize_inline_alert/1)
  end

  defp alert_is_inline?(%{effect: :delay}), do: true
  defp alert_is_inline?(_), do: false

  defp serialize_inline_alert(%{id: id, effect: :delay, severity: severity}) do
    {delay_description, delay_minutes} =
      cond do
        severity < 3 -> {"up to", 10}
        severity > 9 -> {"more than", 60}
        severity >= 8 -> {"more than", 30 * (severity - 7)}
        true -> {"up to", 5 * (severity - 1)}
      end

    delay_text = ["Delays #{delay_description}", %{format: :bold, text: "#{delay_minutes}m"}]
    %{id: id, icon: :clock, text: delay_text, color: :black}
  end
end
