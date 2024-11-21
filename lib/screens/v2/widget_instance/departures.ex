defmodule Screens.V2.WidgetInstance.Departures do
  @moduledoc false

  alias Screens.Departures.Departure
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Util
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures
  alias Screens.V2.WidgetInstance.Serializer.RoutePill
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Departures.Header
  alias ScreensConfig.V2.Departures.Layout
  alias ScreensConfig.V2.FreeTextLine

  defstruct screen: nil, section_data: [], slot_names: [], now: nil

  @type normal_section :: %{
          type: :normal_section,
          rows: list(Departure.t() | notice()),
          layout: Layout.t(),
          header: Header.t()
        }

  @type notice_section :: %{
          type: :notice_section,
          text: FreeTextLine.t()
        }

  @type headway_section :: %{
          type: :headway_section,
          route: :red | :orange | :green | :blue,
          time_range: {integer(), integer()},
          headsign: String.t()
        }

  @type overnight_section :: %{
          type: :overnight_section,
          routes: list(Route.t())
        }

  @type no_data_section :: %{
          type: :no_data_section,
          route: Route.t()
        }

  @type notice :: %{
          text: FreeTextLine.t()
        }

  @type t :: %__MODULE__{
          screen: Screen.t(),
          section_data:
            list(
              normal_section()
              | notice_section()
              | headway_section()
              | overnight_section()
              | no_data_section()
            ),
          slot_names: list(atom()),
          now: DateTime.t()
        }

  # The maximum number of departures to send back to the client.
  # ("Departures" here can be either an actual departure, or a "notice row")
  @max_departures 15

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(%Departures{section_data: section_data, screen: screen, now: now}) do
      %{
        sections:
          Enum.map(
            section_data,
            &Departures.serialize_section(&1, screen, now, length(section_data) == 1)
          )
      }
    end

    def slot_names(%Departures{slot_names: slot_names}) when length(slot_names) > 0,
      do: slot_names

    def slot_names(_instance), do: [:main_content]

    def widget_type(_instance), do: :departures

    def valid_candidate?(_instance), do: true

    def audio_serialize(%Departures{section_data: section_data, screen: screen, now: now}) do
      %{sections: Enum.map(section_data, &Departures.audio_serialize_section(&1, screen, now))}
    end

    def audio_sort_key(_instance), do: [1]

    def audio_valid_candidate?(_instance), do: true

    def audio_view(_instance), do: ScreensWeb.V2.Audio.DeparturesView
  end

  def serialize_section(section, screen, now, is_only_section \\ false)

  def serialize_section(%{type: :notice_section, text: text}, _screen, _now, _) do
    %{type: :notice_section, text: text}
  end

  def serialize_section(%{type: :no_data_section, route: route}, _screen, _now, _) do
    text = %FreeTextLine{
      icon: Route.icon(route),
      text: ["Updates unavailable"]
    }

    %{type: :no_data_section, text: FreeTextLine.to_json(text)}
  end

  def serialize_section(
        %{type: :headway_section, route: route, time_range: {lo, hi}, headsign: headsign},
        _screen,
        _now,
        is_only_section
      ) do
    pill_color = Route.color(route)
    layout = if is_only_section, do: :full_screen, else: :row

    formatted_route =
      case route do
        "Green" <> _ -> "Green"
        route -> route
      end

    text =
      if is_only_section do
        time_range =
          if headsign == "Ashmont/Braintree" do
            [%{format: :bold, text: "#{lo}-#{hi}m"}]
          else
            [%{format: :bold, text: "#{lo}-#{hi}"}, "minutes"]
          end

        %FreeTextLine{
          icon: "subway-negative-black",
          text:
            [
              %{
                color: pill_color,
                text: "#{String.upcase(formatted_route)} LINE"
              },
              %{special: :break},
              "#{headsign} trains every"
            ] ++ time_range
        }
      else
        %FreeTextLine{
          icon: pill_color,
          text: ["every", %{format: :bold, text: "#{lo}-#{hi}"}, "minutes"]
        }
      end

    %{type: :headway_section, text: FreeTextLine.to_json(text), layout: layout}
  end

  def serialize_section(
        %{type: :normal_section, rows: departures, layout: layout, header: header},
        screen,
        now,
        _
      ) do
    rows =
      departures
      |> Enum.take(@max_departures)
      |> group_consecutive_departures(screen)
      |> Enum.map(&serialize_row(&1, screen, now))

    %{
      type: :normal_section,
      rows: rows,
      layout: Layout.to_json(layout),
      header: Header.to_json(header)
    }
  end

  def serialize_section(%{type: :overnight_section, routes: routes}, _, _now, _) do
    route_pill =
      routes
      |> Enum.map(&Route.icon/1)
      |> List.first()

    text = %FreeTextLine{
      icon: route_pill,
      text: [
        "Service resumes",
        %{special: :break},
        "in the morning"
      ]
    }

    %{type: :overnight_section, text: FreeTextLine.to_json(text)}
  end

  def audio_serialize_section(%{type: :notice_section, text: text}, _screen, _now) do
    %{type: :notice_section, text: FreeTextLine.to_plaintext(text)}
  end

  def audio_serialize_section(
        %{type: :normal_section, rows: departures, header: header},
        screen,
        now
      ) do
    header =
      case header do
        %{read_as: header} when is_binary(header) -> header
        %{title: header} when is_binary(header) -> header
        _ -> nil
      end

    serialized_departure_groups =
      departures
      |> group_all_departures(now, screen.app_id)
      |> Enum.map(&audio_serialize_departure_group(&1, screen, now))

    %{
      type: :normal_section,
      header: header,
      departure_groups: serialized_departure_groups
    }
  end

  defp audio_serialize_departure_group({:notice, %{text: text}}, _, _now) do
    {:notice, FreeTextLine.to_plaintext(text)}
  end

  defp audio_serialize_departure_group({:normal, departures}, screen, now) do
    {:normal, serialize_row(departures, screen, now, &RoutePill.serialize_for_audio_departure/4)}
  end

  @doc """
  Groups consecutive departures that have the same route and headsign.
  `notice` rows are never grouped.
  """
  @spec group_consecutive_departures(list(Departure.t() | notice), Screen.t()) ::
          list(list(Departure.t() | notice))
  def group_consecutive_departures(departures, screen)

  def group_consecutive_departures(departures, %Screen{app_id: :dup_v2}) do
    departures
    |> Enum.chunk_by(fn
      _ ->
        make_ref()
    end)
  end

  def group_consecutive_departures(departures, _screen) do
    departures
    |> Enum.chunk_by(fn
      %{text: %FreeTextLine{}} ->
        make_ref()

      d ->
        {Departure.route(d), Departure.headsign(d)}
    end)
  end

  # Groups all departures of the same route and headsign.
  # `notice` rows are never grouped.

  # The list is ordered by the occurrence of the _first_ departure of each group--later departures can "leap frog"
  # ahead of other ones of a different route/headsign if there's an earlier departure of the same route/headsign.
  @spec group_all_departures(
          list(Departure.t() | notice),
          DateTime.t(),
          Screen.app_id()
        ) ::
          list(
            {:normal, list(Departure.t())}
            | {:notice, notice}
          )
  defp group_all_departures(departures, now, app_id) do
    departures
    |> Util.group_by_with_order(fn
      %{text: %FreeTextLine{}} -> make_ref()
      d -> {Departure.route(d), Departure.headsign(d)}
    end)
    |> Enum.map(fn
      {ref, [notice]} when is_reference(ref) ->
        {:notice, notice}

      {_key, departure_group} ->
        departures =
          if app_id == :busway_v2 do
            filter_departure_group(departure_group, now)
          else
            Enum.take(departure_group, 2)
          end

        {:normal, departures}
    end)
  end

  defp filter_departure_group([first_departure | _] = departure_group, now) do
    if first_departure |> Departure.time() |> DateTime.diff(now, :minute) <= 2 do
      Enum.take(departure_group, 2)
    else
      [first_departure]
    end
  end

  defp serialize_row(
         departures_or_notice,
         screen,
         now,
         route_pill_serializer \\ &RoutePill.serialize_for_departure/4
       )

  defp serialize_row([%Departure{} | _] = departures, screen, now, route_pill_serializer) do
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
      headsign: serialize_headsign(departures, screen),
      times_with_crowding: serialize_times_with_crowding(departures, screen, now),
      # Temporarily retained for compatibility with deployed clients that expect this field
      inline_alerts: []
    }
  end

  defp serialize_row([%{text: %FreeTextLine{} = text}], _screen, _now, _pill_serializer) do
    %{
      type: :notice_row,
      text: FreeTextLine.to_json(text)
    }
  end

  def serialize_route([first_departure | _], route_pill_serializer) do
    route = Departure.route(first_departure)
    %Route{id: route_id, type: route_type} = route
    track_number = Departure.track_number(first_departure)

    route_pill_serializer.(route_id, Route.name(route), route_type, track_number)
  end

  def serialize_headsign([first_departure | _], %Screen{app_id: :dup_v2}) do
    headsign = Departure.headsign(first_departure)
    headsign_replacements = Application.get_env(:screens, :dup_headsign_replacements)

    %{headsign: Map.get(headsign_replacements, headsign, headsign)}
  end

  def serialize_headsign([first_departure | _], _) do
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

  def serialize_times_with_crowding(departures, screen, now) do
    Enum.map(departures, &serialize_time_with_crowding(&1, screen, now))
  end

  defp serialize_time_with_crowding(departure, screen, now) do
    serialized_time =
      case Departure.route(departure).type do
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
          serialize_timestamp(departure_time, now)
      end

    # time_in_epoch is used by Mercury so they can calculate timestamps on their own.
    # https://app.asana.com/0/1176097567827729/1205730972991228/f
    %{time: time, time_in_epoch: DateTime.to_unix(departure_time)}
  end

  defp serialize_time(
         %Departure{schedule: %Schedule{arrival_time: nil, departure_time: nil}},
         _screen,
         _now
       ),
       do: %{time: %{type: :overnight}}

  defp serialize_time(departure, _screen, now) do
    %Stop{id: stop_id} = Departure.stop(departure)
    departure_time = Departure.time(departure)
    vehicle_status = Departure.vehicle_status(departure)
    vehicle_stop_id = Prediction.stop_for_vehicle(departure.prediction)
    stop_type = Departure.stop_type(departure)
    %Route{type: route_type} = Departure.route(departure)

    second_diff = DateTime.diff(departure_time, now)
    minute_diff = round(second_diff / 60)

    time =
      cond do
        vehicle_status == :stopped_at and second_diff < 90 and stop_id == vehicle_stop_id ->
          %{type: :text, text: "BRD"}

        second_diff < 30 and stop_type == :first_stop ->
          %{type: :text, text: "BRD"}

        second_diff < 30 ->
          %{type: :text, text: "ARR"}

        minute_diff < 60 and route_type not in [:rail, :ferry] ->
          %{type: :minutes, minutes: minute_diff}

        true ->
          serialize_timestamp(departure_time, now)
      end

    %{time: time}
  end

  defp serialize_time_with_schedule(departure, screen, now) do
    %{time: serialized_time} = serialize_time(departure, screen, now)

    scheduled_time = Departure.scheduled_time(departure)

    if is_nil(scheduled_time) do
      %{time: serialized_time}
    else
      serialized_scheduled_time = serialize_timestamp(scheduled_time, now)

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

  defp serialize_timestamp(departure_time, now) do
    {:ok, local_time} = DateTime.shift_zone(departure_time, "America/New_York")
    hour = 1 + Integer.mod(local_time.hour - 1, 12)
    minute = local_time.minute
    am_pm = if local_time.hour >= 12, do: :pm, else: :am
    show_am_pm = Util.get_service_date_tomorrow(now).day == local_time.day
    %{type: :timestamp, hour: hour, minute: minute, am_pm: am_pm, show_am_pm: show_am_pm}
  end

  defp serialize_crowding(departure) do
    Departure.crowding_level(departure)
  end
end
