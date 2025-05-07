defmodule Screens.V2.WidgetInstance.Departures do
  @moduledoc """
  Provides real-time departure information, consisting of an ordered list of "sections".
  """

  alias Screens.Departures.Departure
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Util
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures
  alias Screens.V2.WidgetInstance.Serializer.RoutePill
  alias ScreensConfig.Departures.Header
  alias ScreensConfig.Departures.Layout
  alias ScreensConfig.{FreeTextLine, Screen}

  defmodule NormalSection do
    @moduledoc "Section which includes a number of independent 'rows' or items."
    alias Screens.V2.Departure
    alias ScreensConfig.Departures.Header
    alias ScreensConfig.Departures.Layout
    alias ScreensConfig.FreeTextLine

    @type row :: Departure.t() | FreeTextLine.t()

    @type t :: %__MODULE__{
            header: Header.t(),
            layout: Layout.t(),
            grouping_type: :time | :destination,
            rows: [row()]
          }
    defstruct header: nil, layout: nil, grouping_type: :time, rows: []
  end

  defmodule HeadwaySection do
    @moduledoc "Section consisting of a 'trains every X-Y minutes' message."
    alias Screens.Headways

    @type t :: %__MODULE__{
            headsign: String.t(),
            route: :red | :orange | :green | :blue,
            time_range: Headways.range()
          }
    defstruct ~w[headsign route time_range]a
  end

  defmodule OvernightSection do
    @moduledoc "Section consisting of a 'service ended' message."
    @type t :: %__MODULE__{routes: [Route.t()]}
    defstruct ~w[routes]a
  end

  defmodule NoDataSection do
    @moduledoc "Section consisting of a 'no departures' message."
    @type t :: %__MODULE__{route: Route.t()}
    defstruct ~w[route]a
  end

  @type section ::
          HeadwaySection.t() | NormalSection.t() | OvernightSection.t() | NoDataSection.t()

  @type t :: %__MODULE__{
          screen: Screen.t(),
          sections: [section()],
          slot_names: list(atom()),
          now: DateTime.t()
        }
  defstruct screen: nil, sections: [], slot_names: [], now: nil

  # Limits how many rows per section will be sent to the client.
  @max_rows_per_section 15

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(%Departures{sections: sections, screen: screen, now: now}) do
      is_only_section = match?([_], sections)

      %{
        sections:
          Enum.map(sections, &Departures.serialize_section(&1, screen, now, is_only_section))
      }
    end

    def slot_names(%Departures{slot_names: []}), do: [:main_content]
    def slot_names(%Departures{slot_names: slot_names}), do: slot_names

    def widget_type(_instance), do: :departures

    def valid_candidate?(_instance), do: true

    def audio_serialize(%Departures{sections: sections, screen: screen, now: now}) do
      %{sections: Enum.map(sections, &Departures.audio_serialize_section(&1, screen, now))}
    end

    def audio_sort_key(_instance), do: [1]

    def audio_valid_candidate?(_instance), do: true

    def audio_view(_instance), do: ScreensWeb.V2.Audio.DeparturesView
  end

  def serialize_section(section, screen, now, is_only_section \\ false)

  def serialize_section(%NoDataSection{route: route}, _screen, _now, _is_only_section) do
    text = %FreeTextLine{
      icon: Route.icon(route),
      text: ["Updates unavailable"]
    }

    %{type: :no_data_section, text: FreeTextLine.to_json(text)}
  end

  def serialize_section(
        %HeadwaySection{route: route, time_range: {lo, hi}, headsign: headsign},
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
        %NormalSection{rows: rows, header: header, grouping_type: :destination},
        screen,
        now,
        _is_only_section
      ) do
    serialized_rows =
      rows
      |> group_by_unique_destination()
      |> Enum.take(@max_rows_per_section)
      |> Enum.map(&serialize_departure_group(&1, screen, now))

    %{
      type: :normal_section,
      rows: serialized_rows,
      layout:
        Layout.to_json(%Layout{
          max: nil,
          base: length(serialized_rows),
          min: 2,
          include_later: false
        }),
      header: Header.to_json(header),
      grouping_type: :destination
    }
  end

  def serialize_section(
        %NormalSection{rows: rows, layout: layout, header: header, grouping_type: grouping_type},
        screen,
        now,
        _is_only_section
      ) do
    serialized_rows =
      rows
      |> Enum.take(@max_rows_per_section)
      |> group_consecutive_departures(screen)
      |> Enum.map(&serialize_departure_group(&1, screen, now))

    %{
      type: :normal_section,
      rows: serialized_rows,
      layout: Layout.to_json(layout),
      header: Header.to_json(header),
      grouping_type: grouping_type
    }
  end

  def serialize_section(%OvernightSection{routes: routes}, _screen, _now, _is_only_section) do
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

  def audio_serialize_section(
        %NormalSection{rows: rows, header: header},
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
      rows
      |> group_section_rows_for_audio(now, screen.app_id)
      |> Enum.map(&audio_serialize_row_group(&1, screen, now))

    %{
      type: :normal_section,
      header: header,
      departure_groups: serialized_departure_groups
    }
  end

  defp audio_serialize_row_group({:notice, free_text}, _, _now) do
    {:notice, FreeTextLine.to_plaintext(free_text)}
  end

  defp audio_serialize_row_group({:normal, departures}, screen, now) do
    {
      :normal,
      serialize_departure_group(
        departures,
        screen,
        now,
        &RoutePill.serialize_for_audio_departure/4
      )
    }
  end

  @doc """
  Groups unique destinations together by their headsign and direction id
  """
  @spec group_by_unique_destination([NormalSection.row()]) :: [[NormalSection.row()]]
  def group_by_unique_destination(rows) do
    rows
    |> Enum.uniq_by(&row_departure_grouping(&1))
    |> Enum.map(&[&1])
  end

  @doc """
  Groups consecutive departures that have the same route and headsign.
  Rows that are not departures are never grouped.
  """
  @spec group_consecutive_departures([NormalSection.row()], Screen.t()) :: [[NormalSection.row()]]
  def group_consecutive_departures(rows, screen)

  def group_consecutive_departures(rows, %Screen{app_id: :dup_v2}) do
    Enum.chunk_by(rows, fn _ -> make_ref() end)
  end

  def group_consecutive_departures(rows, _screen) do
    Enum.chunk_by(rows, &row_departure_grouping(&1))
  end

  # Groups all departures of the same route and headsign.
  #
  # The list is ordered by the occurrence of the _first_ departure of each group - later
  # departures can "leapfrog" ahead of other ones of a different route/headsign if there's an
  # earlier departure of the same route/headsign.
  @spec group_section_rows_for_audio(
          [NormalSection.row()],
          DateTime.t(),
          Screen.app_id()
        ) ::
          list({:normal, [Departure.t()]} | {:notice, FreeTextLine.t()})
  defp group_section_rows_for_audio(rows, now, app_id) do
    rows
    |> Util.group_by_with_order(&row_departure_grouping(&1))
    |> Enum.map(fn
      {ref, [%FreeTextLine{} = text]} when is_reference(ref) ->
        {:notice, text}

      {_key, [%Departure{} | _] = departures} ->
        {:normal, filter_audio_departure_group(departures, app_id, now)}
    end)
  end

  defp row_departure_grouping(%Departure{} = row),
    do: {Departure.route(row), Departure.headsign(row)}

  defp row_departure_grouping(%FreeTextLine{}), do: make_ref()

  defp filter_audio_departure_group([first_departure | _] = departure_group, :busway_v2, now) do
    if first_departure |> Departure.time() |> DateTime.diff(now, :minute) <= 2 do
      Enum.take(departure_group, 2)
    else
      [first_departure]
    end
  end

  defp filter_audio_departure_group(departures, _app_id, _now) do
    Enum.take(departures, 2)
  end

  defp serialize_departure_group(
         rows,
         screen,
         now,
         route_pill_serializer \\ &RoutePill.serialize_for_departure/4
       )

  defp serialize_departure_group(
         [%Departure{} | _] = departures,
         screen,
         now,
         route_pill_serializer
       ) do
    row_id =
      departures
      |> Enum.map(&Departure.id/1)
      |> Enum.sort()
      |> Enum.join("")
      |> then(&:crypto.hash(:md5, &1))
      |> Base.encode64()

    %{
      id: row_id,
      type: :departure_row,
      route: serialize_route(departures, route_pill_serializer),
      headsign: serialize_headsign(departures, screen),
      times_with_crowding: serialize_times_with_crowding(departures, screen, now),
      direction_id: serialize_direction_id(departures),
      # Temporarily retained for compatibility with deployed clients that expect this field
      inline_alerts: []
    }
  end

  defp serialize_departure_group([%FreeTextLine{} = text], _screen, _now, _pill_serializer) do
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
        Departure.crowding_level(departure)
      else
        nil
      end

    Map.merge(serialized_time, %{
      id: Departure.id(departure),
      crowding: crowding
    })
  end

  def serialize_direction_id([first_departure | _]) do
    Departure.direction_id(first_departure)
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
    local_time = Util.to_eastern(departure_time)
    hour = 1 + Integer.mod(local_time.hour - 1, 12)
    minute = local_time.minute
    am_pm = if local_time.hour >= 12, do: :pm, else: :am
    service_date_tomorrow = now |> Util.service_date() |> Date.add(1)
    show_am_pm = local_time.day == service_date_tomorrow.day
    %{type: :timestamp, hour: hour, minute: minute, am_pm: am_pm, show_am_pm: show_am_pm}
  end
end
