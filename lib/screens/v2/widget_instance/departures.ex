defmodule Screens.V2.WidgetInstance.Departures do
  @moduledoc """
  Provides real-time departure information, consisting of an ordered list of "sections".
  """

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
  alias ScreensConfig.Screen.PreFare

  defmodule NormalSection do
    @moduledoc "Section which includes a number of independent 'rows' or items."

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
            headsign: String.t() | nil,
            route: Route.id(),
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

  defmodule NoServiceSection do
    @moduledoc "Section consisting of a 'no service' message."
    @type t :: %__MODULE__{route: Route.t()}
    defstruct ~w[route]a
  end

  @type section ::
          HeadwaySection.t()
          | NormalSection.t()
          | OvernightSection.t()
          | NoDataSection.t()
          | NoServiceSection.t()

  @type t :: %__MODULE__{
          screen: Screen.t(),
          sections: [section()],
          slot_names: list(atom()),
          now: DateTime.t()
        }
  defstruct screen: nil, sections: [], slot_names: [], now: nil

  # Possible type representations for predictions and schedules
  # for the client to determine how to display the time until departure.
  @type serialized_text :: %{type: :text, text: String.t()}
  @type serialized_minutes :: %{type: :minutes, minutes: non_neg_integer()}
  @type serialized_timestamp :: %{
          type: :timestamp,
          hour: pos_integer(),
          minute: non_neg_integer(),
          am_pm: :am | :pm | nil
        }
  @type serialized_status :: %{type: :status, pages: [String.t()]}
  @type serialized_overnight :: %{type: :overnight}

  @typedoc "All possible serialized time representations"
  @type serialized_time ::
          serialized_text()
          | serialized_minutes()
          | serialized_timestamp()
          | serialized_status()
          | serialized_overnight()

  @typep serialized_time_with_crowding :: %{
           required(:id) => String.t(),
           required(:time) => serialized_time(),
           required(:scheduled_time) => serialized_timestamp() | nil,
           required(:crowding) => pos_integer() | nil,
           optional(:time_in_epoch) => integer()
         }

  # Limits how many rows per section will be sent to the client.
  @max_rows_per_section 15
  @sl_route_ids ~w[741 742 743 746 749 751]

  defimpl Screens.V2.WidgetInstance do
    def priority(%Departures{screen: %Screen{app_params: %PreFare{}}}), do: [1]
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

    def audio_sort_key(%Departures{screen: %Screen{app_params: %PreFare{}}}), do: [2]

    def audio_sort_key(_instance), do: [1]

    def audio_valid_candidate?(_instance), do: true

    def audio_view(_instance), do: ScreensWeb.V2.Audio.DeparturesView
  end

  def serialize_section(section, screen, now, is_only_section \\ false)

  def serialize_section(%NoDataSection{route: route}, _screen, _now, _is_only_section) do
    text = %FreeTextLine{
      icon: if(route == nil, do: nil, else: Route.icon(route)),
      text: ["Updates unavailable"]
    }

    %{type: :no_data_section, text: FreeTextLine.to_json(text)}
  end

  def serialize_section(%NoServiceSection{route: route}, _screen, _now, _is_only_section) do
    text = %FreeTextLine{
      icon: if(route == nil, do: nil, else: Route.icon(route)),
      text: ["No Service today"]
    }

    %{type: :no_service_section, text: FreeTextLine.to_json(text)}
  end

  def serialize_section(
        %HeadwaySection{route: route, time_range: time_range, headsign: headsign},
        _screen,
        _now,
        is_only_section
      ) do
    pill_color = Route.color(route)
    layout = if is_only_section, do: :full_screen, else: :row

    text = get_headway_text(headsign, time_range, pill_color, route, is_only_section)

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
    route_pill = routes |> Enum.map(&Route.icon/1) |> List.first()
    text = %FreeTextLine{icon: route_pill, text: ["Service ended"]}

    %{type: :overnight_section, text: FreeTextLine.to_json(text)}
  end

  def audio_serialize_section(%NormalSection{header: header} = section, screen, now) do
    header =
      case header do
        %{read_as: header} when is_binary(header) ->
          header

        %{title: title, subtitle: subtitle} when is_binary(title) and is_binary(subtitle) ->
          "#{title}. #{String.replace(subtitle, "*", "")}"

        %{title: header} when is_binary(header) ->
          header

        _ ->
          nil
      end

    serialized_departure_groups =
      section
      |> group_section_rows_for_audio(screen.app_id, now)
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
  @spec group_section_rows_for_audio(NormalSection.t(), Screen.app_id(), now :: DateTime.t()) ::
          list({:normal, [Departure.t()]} | {:notice, FreeTextLine.t()})
  defp group_section_rows_for_audio(
         %NormalSection{rows: rows, grouping_type: grouping_type} = section,
         app_id,
         now
       ) do
    rows
    |> take_max_rows_for_audio(section)
    |> Util.group_by_with_order(&row_departure_grouping(&1))
    |> Enum.map(fn
      {ref, [%FreeTextLine{} = text]} when is_reference(ref) ->
        {:notice, text}

      {_key, [%Departure{} | _] = departures} ->
        {:normal, filter_audio_departure_group(departures, grouping_type, app_id, now)}
    end)
  end

  # Don't limit total rows when using destination-based grouping.
  defp take_max_rows_for_audio(rows, %NormalSection{grouping_type: :destination}), do: rows

  # Try to limit the readout to a reasonable number of departures based on the configured layout.
  # Assume "Later Departures" fits a certain fixed number of additional departures; this will not
  # align precisely with the visual presentation.
  defp take_max_rows_for_audio(rows, %NormalSection{
         layout: %Layout{base: base, max: max, include_later: include_later}
       }) do
    Enum.take(rows, (max || base || @max_rows_per_section) + if(include_later, do: 4, else: 0))
  end

  defp row_departure_grouping(%Departure{} = row),
    do: {Departure.route(row), Departure.headsign(row)}

  defp row_departure_grouping(%FreeTextLine{}), do: make_ref()

  # When using destination-based grouping, only read out the "next" departure, in line with the
  # visual presentation.
  defp filter_audio_departure_group([first_departure | _], :destination, _app_id, _now) do
    [first_departure]
  end

  # On Sectionals using time-based grouping, only read out the "following" departure when the
  # "next" one is very soon.
  defp filter_audio_departure_group([first_departure | _] = group, :time, :busway_v2, now) do
    if first_departure |> Departure.time() |> DateTime.diff(now, :minute) <= 2 do
      Enum.take(group, 2)
    else
      [first_departure]
    end
  end

  # By default, when using time-based grouping, always read out both the "next" and "following"
  # departure if available.
  defp filter_audio_departure_group(departures, :time, _app_id, _now) do
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

  @spec serialize_time_with_crowding(Departure.t(), Screen.t(), DateTime.t()) ::
          serialized_time_with_crowding()
  defp serialize_time_with_crowding(departure, screen, now) do
    serialize_time(departure, screen, now)
    |> Map.merge(%{id: Departure.id(departure), crowding: serialize_crowding(departure, screen)})
  end

  def serialize_direction_id([first_departure | _]) do
    Departure.direction_id(first_departure)
  end

  # DUPs don't display crowding information (space constraints, no design implemented for it).
  defp serialize_crowding(_departure, %Screen{app_id: :dup_v2}), do: nil
  # Otherwise, include crowding information for any valid departure.
  # Will return nil for schedules or predictions without crowding data.
  defp serialize_crowding(departure, _screen), do: Departure.crowding_level(departure)

  @spec serialize_time(Departure.t(), Screen.t(), DateTime.t()) ::
          %{time: serialized_time(), time_in_epoch: integer()}
          | %{time: serialized_time() | nil, scheduled_time: serialized_timestamp() | nil}
  defp serialize_time(departure, %Screen{app_id: app_id} = screen, now)
       when app_id in [:bus_eink_v2, :gl_eink_v2] do
    departure_time = Departure.time(departure)
    second_diff = DateTime.diff(departure_time, now)
    minute_diff = round(second_diff / 60)

    time =
      cond do
        second_diff < 60 -> %{type: :text, text: "Now"}
        minute_diff < 60 -> %{type: :minutes, minutes: minute_diff}
        true -> serialize_timestamp(departure_time, screen, now)
      end

    # See `docs/mercury_api.md`
    %{time: time, time_in_epoch: DateTime.to_unix(departure_time)}
  end

  defp serialize_time(
         %Departure{schedule: %Schedule{arrival_time: nil, departure_time: nil}},
         _screen,
         _now
       ),
       do: %{time: %{type: :overnight}}

  defp serialize_time(%Departure{prediction: prediction} = departure, screen, now) do
    scheduled_time = Departure.scheduled_time(departure)
    %Route{type: route_type} = Departure.route(departure)
    include_scheduled_time? = route_type in [:ferry, :rail]
    predicted? = not is_nil(prediction)

    serialized_time =
      cond do
        Departure.cancelled?(departure) -> nil
        predicted? and not include_scheduled_time? -> serialize_realtime(departure, screen, now)
        true -> departure |> Departure.time() |> serialize_timestamp(screen, now)
      end

    serialized_scheduled_time =
      if include_scheduled_time? and not is_nil(scheduled_time) do
        serialized_scheduled_time = serialize_timestamp(scheduled_time, screen, now)

        case serialized_time do
          %{type: :text} -> nil
          ^serialized_scheduled_time -> nil
          _ -> serialized_scheduled_time
        end
      end

    %{time: serialized_time, scheduled_time: serialized_scheduled_time}
  end

  @spec serialize_realtime(Departure.t(), Screen.t(), DateTime.t()) :: serialized_time()
  defp serialize_realtime(
         %Departure{
           prediction: %Prediction{stop: %Stop{id: stop_id}, status: status} = prediction
         } = departure,
         screen,
         now
       ) do
    at_first_stop? = Departure.stop_type(departure) == :first_stop
    departure_time = Departure.time(departure)
    second_diff = DateTime.diff(departure_time, now)
    minute_diff = round(second_diff / 60)
    status_pages = parse_status_pages(status, screen)

    stopped_at_predicted_stop? =
      Departure.vehicle_status(departure) == :stopped_at and
        stop_id == Prediction.stop_for_vehicle(prediction)

    cond do
      status_pages != nil -> %{type: :status, pages: status_pages}
      second_diff < 90 and stopped_at_predicted_stop? -> %{type: :text, text: "BRD"}
      second_diff < 30 and at_first_stop? -> %{type: :text, text: "BRD"}
      second_diff < 30 -> %{type: :text, text: "ARR"}
      minute_diff < 60 -> %{type: :minutes, minutes: minute_diff}
      true -> serialize_timestamp(departure_time, screen, now)
    end
  end

  @spec serialize_timestamp(DateTime.t(), Screen.t(), DateTime.t()) ::
          serialized_timestamp()
  defp serialize_timestamp(datetime, %Screen{app_id: app_id}, now) do
    local_time = Util.to_eastern(datetime)
    hour = 1 + Integer.mod(local_time.hour - 1, 12)
    minute = local_time.minute
    am_pm = if local_time.hour >= 12, do: :pm, else: :am
    service_date_tomorrow = now |> Util.service_date() |> Date.add(1)
    # Screen types other than DUPs currently have no implemented design for the AM/PM indicator.
    show_am_pm = app_id == :dup_v2 and local_time.day == service_date_tomorrow.day

    %{type: :timestamp, hour: hour, minute: minute, am_pm: if(show_am_pm, do: am_pm, else: nil)}
  end

  defp get_headway_text(
         headsign,
         {lo, hi},
         pill_color,
         route,
         true = _is_only_section
       ) do
    time_range =
      if headsign == "Ashmont/Braintree" do
        [%{format: :bold, text: "#{lo}-#{hi}m"}]
      else
        [%{format: :bold, text: "#{lo}-#{hi}"}, "minutes"]
      end

    {formatted_route, vehicle} =
      cond do
        String.starts_with?(route, "Green") -> {"Green", "trains"}
        route in @sl_route_ids -> {"Silver", "buses"}
        true -> {route, "trains"}
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
          "#{headsign} #{vehicle} every"
        ] ++ time_range
    }
  end

  defp get_headway_text(
         nil,
         {lo, hi},
         pill_color,
         _formatted_route,
         false = _is_only_section
       ) do
    %FreeTextLine{
      icon: pill_color,
      text: ["every", %{format: :bold, text: "#{lo}-#{hi}"}, "minutes"]
    }
  end

  defp get_headway_text(
         headsign,
         {lo, hi},
         pill_color,
         _formatted_route,
         false = _is_only_section
       ) do
    %FreeTextLine{
      icon: pill_color,
      text: [%{format: :bold, text: headsign}, %{format: :small, text: "every #{lo}-#{hi}m"}]
    }
  end

  @spec parse_status_pages(String.t() | nil, Screen.t()) :: [String.t()] | nil
  defp parse_status_pages(status, %Screen{app_id: :dup_v2}) when not is_nil(status) do
    # Status is only used on DUPs at this time. Matches "Stopped X stop(s) away" pattern
    # and returns pages like ["Stopped", "3 stops away"] or ["Stopped", "1 stop away"]
    Regex.run(~r/(Stopped) (\d+ stops? away)/, status, capture: :all_but_first)
  end

  defp parse_status_pages(_status, _screen), do: nil
end
