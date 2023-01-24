defmodule Screens.V2.WidgetInstance.Departures do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Dup.Override.FreeTextLine
  alias Screens.Config.Screen
  alias Screens.Util
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures
  alias Screens.V2.WidgetInstance.Serializer.RoutePill

  defstruct screen: nil,
            section_data: [],
            slot_names: []

  @type section :: %{
          type: :normal_section,
          rows: list(Departure.t() | notice())
        }

  @type notice_section :: %{
          type: :notice_section,
          text: FreeTextLine.t()
        }

  @type notice :: %{
          text: FreeTextLine.t()
        }

  @type t :: %__MODULE__{
          screen: Screen.t(),
          section_data: list(section | notice_section),
          slot_names: list(atom())
        }

  # The maximum number of departures to send back to the client.
  # ("Departures" here can be either an actual departure, or a "notice row")
  @max_departures 15

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(%Departures{section_data: section_data, screen: screen}) do
      %{sections: Enum.map(section_data, &Departures.serialize_section(&1, screen))}
    end

    def slot_names(%Departures{slot_names: slot_names}) when length(slot_names) > 0,
      do: slot_names

    def slot_names(_instance), do: [:main_content, :main_content_zero]

    def widget_type(_instance), do: :departures

    def valid_candidate?(_instance), do: true

    def audio_serialize(%Departures{section_data: section_data, screen: screen}) do
      %{sections: Enum.map(section_data, &Departures.audio_serialize_section(&1, screen))}
    end

    def audio_sort_key(_instance), do: [1]

    def audio_valid_candidate?(_instance), do: true

    def audio_view(_instance), do: ScreensWeb.V2.Audio.DeparturesView
  end

  def serialize_section(%{type: :notice_section, text: text}, _screen) do
    %{type: :notice_section, text: text}
  end

  def serialize_section(%{type: :normal_section, rows: departures}, screen) do
    rows =
      departures
      |> Enum.take(@max_departures)
      |> group_consecutive_departures(screen)
      |> Enum.map(&serialize_row(&1, screen))

    %{type: :normal_section, rows: rows}
  end

  def audio_serialize_section(%{type: :notice_section, text: text}, _screen) do
    %{type: :notice_section, text: FreeTextLine.to_plaintext(text)}
  end

  def audio_serialize_section(%{type: :normal_section, rows: departures}, screen) do
    serialized_departure_groups =
      departures
      |> group_all_departures(2)
      |> Enum.map(&audio_serialize_departure_group(&1, screen))

    %{
      type: :normal_section,
      departure_groups: serialized_departure_groups
    }
  end

  defp audio_serialize_departure_group({:notice, %{text: text}}, _) do
    {:notice, FreeTextLine.to_plaintext(text)}
  end

  defp audio_serialize_departure_group({:normal, departures}, screen) do
    {:normal, serialize_row(departures, screen, &RoutePill.serialize_for_audio_departure/4)}
  end

  @doc """
  Groups consecutive departures that have the same route and headsign.
  `notice` rows are never grouped.
  """
  @spec group_consecutive_departures(list(Departure.t() | notice), Screen.t()) ::
          list(list(Departure.t() | notice))
  def group_consecutive_departures(departures, %Screen{app_id: app_id}) do
    departures
    |> Enum.chunk_by(fn
      %{text: %FreeTextLine{}} ->
        make_ref()

      d ->
        if app_id == :dup_v2 do
          make_ref()
        else
          {Departure.route_id(d), Departure.headsign(d)}
        end
    end)
  end

  @doc """
  Groups all departures of the same route and headsign, limiting each group to `max_entries_per_group` entries.
  `notice` rows are never grouped.

  The list is ordered by the occurrence of the _first_ departure of each group--later departures can "leap frog"
  ahead of other ones of a different route/headsign if there's an earlier departure of the same route/headsign.
  """
  @spec group_all_departures(list(Departure.t() | notice), integer) ::
          list(
            {:normal, list(Departure.t())}
            | {:notice, notice}
          )
  def group_all_departures(departures, max_entries_per_group) do
    departures
    |> Util.group_by_with_order(fn
      %{text: %FreeTextLine{}} -> make_ref()
      d -> {Departure.route_id(d), Departure.headsign(d)}
    end)
    |> Enum.map(fn
      {ref, [notice]} when is_reference(ref) ->
        {:notice, notice}

      {_key, departure_group} ->
        {:normal, Enum.take(departure_group, max_entries_per_group)}
    end)
  end

  defp serialize_row(
         departures_or_notice,
         screen,
         route_pill_serializer \\ &RoutePill.serialize_for_departure/4
       )

  defp serialize_row([%Departure{} | _] = departures, screen, route_pill_serializer) do
    departure_id_string =
      departures
      |> Enum.map(&Departure.id/1)
      |> Enum.sort()
      |> Enum.join("")

    row_id = :md5 |> :crypto.hash(departure_id_string) |> Base.encode64()

    %{
      id: row_id,
      type: :departure_row,
      route: serialize_route(departures, route_pill_serializer),
      headsign: serialize_headsign(departures),
      times_with_crowding: serialize_times_with_crowding(departures, screen),
      inline_alerts: serialize_inline_alerts(departures)
    }
  end

  defp serialize_row([%{text: %FreeTextLine{} = text}], _screen, _pill_serializer) do
    %{
      type: :notice_row,
      text: FreeTextLine.to_json(text)
    }
  end

  def serialize_route([first_departure | _], route_pill_serializer) do
    route_id = Departure.route_id(first_departure)
    route_name = Departure.route_name(first_departure)
    route_type = Departure.route_type(first_departure)
    track_number = Departure.track_number(first_departure)

    route_pill_serializer.(route_id, route_name, route_type, track_number)
  end

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

    crowding =
      if crowding_compatible?(serialized_time, screen) do
        serialize_crowding(departure)
      else
        nil
      end

    Map.merge(serialized_time, %{
      id: Departure.id(departure),
      crowding: crowding
    })
  end

  # Timestamps represent a time further in the future (except for CR, which doesn't have crowding)
  # and can't physically fit on the same row as crowding icons.
  # All other time representations are compatible.
  defp crowding_compatible?(serialized_time, screen)
  defp crowding_compatible?(%{time: %{type: :timestamp}}, _), do: false
  defp crowding_compatible?(_, %Screen{app_id: :dup_v2}), do: false
  defp crowding_compatible?(_, _), do: true

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp serialize_time(departure, %Screen{app_id: app_id}, now)
       when app_id in [:bus_eink_v2, :gl_eink_v2] do
    departure_time = Departure.time(departure)

    second_diff = DateTime.diff(departure_time, now)
    minute_diff = round(second_diff / 60)

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
    minute_diff = round(second_diff / 60)

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

  defp alert_is_inline?(%{effect: :delay}), do: false
  defp alert_is_inline?(_), do: false

  defp serialize_inline_alert(%{id: id, effect: :delay, severity: severity}) do
    {delay_description, delay_minutes} = Alert.interpret_severity(severity)

    delay_description_text =
      case delay_description do
        :up_to -> "Delays up to"
        :more_than -> "Delays more than"
      end

    delay_text = [delay_description_text, %{format: :bold, text: "#{delay_minutes}m"}]
    %{id: id, icon: :clock, text: delay_text, color: :black}
  end
end
