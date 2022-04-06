defmodule Screens.V2.WidgetInstance.ElevatorStatus do
  @moduledoc false

  defmodule DetailPage do
    @moduledoc false

    alias Screens.V2.WidgetInstance.ElevatorStatus

    @type t :: %__MODULE__{
            station: ElevatorStatus.station()
          }

    @derive Jason.Encoder

    defstruct station: nil
  end

  defmodule ListPage do
    @moduledoc false

    alias Screens.V2.WidgetInstance.ElevatorStatus

    @type t :: %__MODULE__{
            stations: list(ElevatorStatus.station())
          }

    @derive Jason.Encoder

    defstruct stations: nil
  end

  defmodule AnnotatedStationRow do
    @moduledoc false

    alias Screens.V2.WidgetInstance.ElevatorStatus

    @type t :: %__MODULE__{
            station: ElevatorStatus.station(),
            height: non_neg_integer()
          }

    @enforce_keys ~w[station height]a
    defstruct @enforce_keys

    @station_row_base_height 100
    @closure_height 48

    def new(station), do: %__MODULE__{station: station, height: height(station)}

    defp height({_station_id, alerts}) do
      @station_row_base_height + @closure_height * length(alerts)
    end
  end

  @subway_icons ~w[red blue orange green silver]a

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{ElevatorStatus, PreFare}

  defstruct screen: nil,
            now: nil,
            alerts: nil,
            stop_sequences: nil,
            facility_id_to_name: nil,
            station_id_to_name: nil,
            station_id_to_icons: nil

  @type icon ::
          :red
          | :blue
          | :orange
          | :green
          | :silver
          | :rail
          | :bus
          | :mattapan

  @type timeframe :: %{
          happening_now: boolean(),
          active_period: map()
        }

  @type closure :: %{
          elevator_name: String.t(),
          elevator_id: String.t(),
          timeframe: timeframe(),
          description: String.t()
        }

  @type station :: %{
          name: String.t(),
          icons: list(icon()),
          elevator_closures: list(closure()),
          is_at_home_stop: boolean()
        }

  @type stop_id :: String.t()

  @type facility :: %{
          name: String.t(),
          id: String.t()
        }

  @type t :: %__MODULE__{
          screen: Screen.t(),
          now: DateTime.t(),
          alerts: list(Alert.t()),
          stop_sequences: list(list(stop_id())),
          facility_id_to_name: %{String.t() => String.t()},
          station_id_to_name: %{String.t() => String.t()},
          station_id_to_icons: %{String.t() => list(icon)}
        }

  def parent_station_id(%__MODULE__{
        screen: %Screen{
          app_params: %PreFare{
            elevator_status: %ElevatorStatus{parent_station_id: parent_station_id}
          }
        }
      }) do
    parent_station_id
  end

  def platform_stop_ids(%__MODULE__{
        screen: %Screen{
          app_params: %PreFare{
            elevator_status: %ElevatorStatus{platform_stop_ids: platform_stop_ids}
          }
        }
      }) do
    platform_stop_ids
  end

  defp get_active_at_home_station(%__MODULE__{alerts: alerts} = t) do
    alerts
    |> Enum.filter(&active_at_home_station?(&1, t))
  end

  defp get_active_elsewhere(
         %__MODULE__{
           alerts: alerts
         } = t
       ) do
    alerts
    |> Enum.filter(&active_elsewhere?(&1, t))
    |> Enum.sort_by(
      fn %Alert{informed_entities: entities} -> entities end,
      &sort_elsewhere(&1, &2, t)
    )
  end

  defp get_upcoming_at_home_station(%__MODULE__{alerts: alerts} = t) do
    alerts
    |> Enum.filter(&upcoming_at_home_station?(&1, t))
  end

  defp get_active_on_connecting_lines(%__MODULE__{alerts: alerts} = t) do
    alerts
    |> Enum.filter(&active_on_connecting_lines?(&1, t))
    |> Enum.sort_by(
      fn %Alert{informed_entities: entities} -> entities end,
      &sort_elsewhere(&1, &2, t)
    )
  end

  defp active_at_home_station?(
         %Alert{effect: :elevator_closure, informed_entities: entities} = alert,
         %__MODULE__{
           now: now
         } = t
       ) do
    parent_station_id = parent_station_id(t)

    Alert.happening_now?(alert, now) and
      Enum.any?(entities, fn entity ->
        entity.stop == parent_station_id
      end)
  end

  defp active_elsewhere?(
         %Alert{effect: :elevator_closure, informed_entities: entities} = alert,
         %__MODULE__{
           now: now
         } = t
       ) do
    stations = get_stations_from_entities(entities)
    parent_station_id = parent_station_id(t)

    Alert.happening_now?(alert, now) and
      Enum.any?(stations, fn station ->
        station != parent_station_id
      end)
  end

  defp upcoming_at_home_station?(
         %Alert{effect: :elevator_closure, informed_entities: entities} = alert,
         %__MODULE__{now: now} = t
       ) do
    parent_station_id = parent_station_id(t)

    not Alert.happening_now?(alert, now) and
      Enum.any?(entities, fn entity ->
        entity.stop == parent_station_id
      end)
  end

  defp active_on_connecting_lines?(
         %Alert{effect: :elevator_closure, informed_entities: entities} = alert,
         %__MODULE__{now: now, stop_sequences: stop_sequences} = t
       ) do
    informed_platforms =
      for %{stop: stop} when is_binary(stop) <- entities,
          match?("place-" <> _, stop),
          do: stop

    # Remove parent station so it does not show up as on a connecting line.
    connecting_platform_ids =
      stop_sequences |> List.flatten() |> List.delete(parent_station_id(t))

    Alert.happening_now?(alert, now) and
      Enum.any?(informed_platforms, &(&1 in connecting_platform_ids))
  end

  defp sort_elsewhere(e1, _e2, %__MODULE__{stop_sequences: stop_sequences}) do
    stations = get_stations_from_entities(e1)

    flat_stop_sequences =
      stop_sequences
      |> List.flatten()

    # NOTE: fix this, stop sequences never contain parent station IDs
    # https://app.asana.com/0/1185117109217422/1202001224916109/f
    Enum.any?(stations, fn station ->
      station in flat_stop_sequences
    end)
  end

  defp get_stations_from_entities(entities) do
    for %{stop: "place-" <> _ = stop_id} <- entities, do: stop_id
  end

  defp get_informed_facility(entities, facilities) do
    informed_facility_id =
      entities
      |> Enum.find_value(fn
        %{facility: facility} -> facility
        _ -> false
      end)

    %{id: informed_facility_id, name: Map.fetch!(facilities, informed_facility_id)}
  end

  defp serialize_closure(alert, %{name: name, id: id}, now) do
    %{
      elevator_name: name,
      elevator_id: id,
      timeframe: serialize_timeframe(alert, now),
      description: alert.description,
      header_text: alert.header
    }
  end

  defp serialize_station(
         {parent_station_id, alerts},
         %__MODULE__{
           facility_id_to_name: facility_id_to_name,
           station_id_to_name: station_id_to_name,
           station_id_to_icons: station_id_to_icons,
           now: now
         } = t
       ) do
    station_name = Map.fetch!(station_id_to_name, parent_station_id)

    closures =
      alerts
      |> Enum.sort_by(&get_informed_facility(&1.informed_entities, facility_id_to_name))
      |> Enum.map(fn %Alert{
                       informed_entities: entities
                     } = alert ->
        facility = get_informed_facility(entities, facility_id_to_name)

        serialize_closure(alert, facility, now)
      end)

    icons =
      station_id_to_icons
      |> Map.fetch!(parent_station_id)
      # Prioritize subway (and Silver Line) route icons
      |> Enum.sort_by(&if(&1 in @subway_icons, do: 0, else: 1))
      |> Enum.take(3)

    %{
      name: station_name,
      icons: icons,
      elevator_closures: closures,
      is_at_home_stop: parent_station_id == parent_station_id(t)
    }
  end

  defp serialize_timeframe(%Alert{active_period: active_period} = alert, now) do
    next_active_period = List.first(active_period)

    %{
      happening_now: Alert.happening_now?(alert, now),
      active_period: Alert.ap_to_map(next_active_period)
    }
  end

  # Groups alerts by their informed parent station ID, and then sorts the station groups
  # by number of subway routes shared between that station and the home station, descending.
  defp sorted_alerts_by_station(alerts, t) do
    subway_routes_at_home_station =
      t.station_id_to_icons[parent_station_id(t)]
      |> Enum.filter(&(&1 in @subway_icons))
      |> MapSet.new()

    alerts
    |> Enum.group_by(&get_parent_station_id_from_informed_entities(&1.informed_entities))
    |> Enum.sort_by(
      fn {station_id, _} ->
        routes_at_alerted_station = MapSet.new(t.station_id_to_icons[station_id])

        routes_at_alerted_station
        |> MapSet.intersection(subway_routes_at_home_station)
        |> MapSet.size()
      end,
      :desc
    )
  end

  defp get_parent_station_id_from_informed_entities(entities) do
    entities
    |> Enum.find_value(fn
      %{stop: "place-" <> _ = parent_station_id} -> parent_station_id
      _ -> false
    end)
  end

  defp serialize_detail_page(
         alert,
         %__MODULE__{} = t
       ) do
    station =
      [alert]
      |> sorted_alerts_by_station(t)
      |> Enum.map(&serialize_station(&1, t))
      |> hd()

    %DetailPage{
      station: station
    }
  end

  defp serialize_list_pages(alerts, pinned_alerts \\ [], t) do
    pinned_stations = sorted_alerts_by_station(pinned_alerts, t)

    stations = sorted_alerts_by_station(alerts, t)

    pages = split_station_pages(stations, pinned_stations)

    Enum.map(pages, fn stations ->
      %ListPage{stations: Enum.map(stations, &serialize_station(&1, t))}
    end)
  end

  @max_page_height 760

  # Splits a list of station rows into several lists, each small enough to fit on a page.
  # list(station_row) -> list(list(station_row))
  defp split_station_pages(stations, pinned_stations) do
    annotated_stations = Enum.map(stations, &AnnotatedStationRow.new/1)

    annotated_pinned_stations = Enum.map(pinned_stations, &AnnotatedStationRow.new/1)

    pages =
      split_station_pages(
        annotated_stations,
        annotated_pinned_stations,
        [annotated_pinned_stations]
      )

    # Get the station rows back from the AnnotatedStationRow structs
    Enum.map(pages, fn annotated_stations ->
      Enum.map(annotated_stations, & &1.station)
    end)
  end

  defp split_station_pages([], _pinned_stations, acc), do: Enum.reverse(acc)

  defp split_station_pages(
         [station | rest_stations] = stations,
         pinned_stations,
         [acc_page | rest_acc_pages] = acc_pages
       ) do
    # If the station row fits on the page we're populating,
    if page_height(acc_page) + station.height <= @max_page_height do
      # Append it on the page and continue fitting the rest of the station rows
      split_station_pages(rest_stations, pinned_stations, [acc_page ++ [station] | rest_acc_pages])
    else
      # Create a new page populated with the pinned station rows, and try again
      split_station_pages(stations, pinned_stations, [pinned_stations | acc_pages])
    end
  end

  defp page_height(annotated_station_rows) do
    annotated_station_rows
    |> Enum.map(& &1.height)
    |> Enum.sum()
  end

  @max_page_count 3

  defp scenario_b_pages(t) do
    active_at_home = get_active_at_home_station(t)

    active_at_home_detail_pages = Enum.map(active_at_home, &serialize_detail_page(&1, t))

    pages =
      if length(active_at_home_detail_pages) >= @max_page_count do
        # Skip the extra work to populate list view pages if they're completely displaced by detail pages
        active_at_home_detail_pages
      else
        active_elsewhere = get_active_elsewhere(t)

        list_pages = serialize_list_pages(active_elsewhere, active_at_home, t)

        active_at_home_detail_pages ++ list_pages
      end

    Enum.take(pages, @max_page_count)
  end

  defp scenario_c_pages(t) do
    list_pages =
      t
      |> get_active_elsewhere()
      |> serialize_list_pages(t)

    upcoming_at_home_detail_pages =
      t
      |> get_upcoming_at_home_station()
      |> Enum.map(&serialize_detail_page(&1, t))

    active_on_connecting_lines_detail_pages =
      t
      |> get_active_on_connecting_lines()
      |> Enum.map(&serialize_detail_page(&1, t))

    (list_pages ++ upcoming_at_home_detail_pages ++ active_on_connecting_lines_detail_pages)
    |> Enum.take(@max_page_count)
  end

  # Determines the scenario we're currently in, as defined at
  # https://app.abstract.com/projects/c04b5940-4805-11e8-8262-510af7fd49fe/branches/f6705d99-fa8b-4115-a97f-188ea9e01a11/collections/91521734-0e0f-434b-bf25-13516d47b1f3
  #
  # To summarize:
  # Scenario A: This screen's "home elevator" is closed. (Only possible on elevator screens)
  # Scenario B: One or more elevators at this screen's home station are closed.
  # Scenario C: All elevators at this screen's home station are operational.
  defp scenario(%__MODULE__{alerts: alerts} = t) do
    if Enum.any?(alerts, &active_at_home_station?(&1, t)), do: :b, else: :c
  end

  def priority(_instance), do: [2]

  def serialize(%__MODULE__{} = t) do
    pages =
      case scenario(t) do
        :b -> scenario_b_pages(t)
        :c -> scenario_c_pages(t)
      end

    %{pages: pages}
  end

  def slot_names(_instance), do: [:lower_right]

  def widget_type(_instance), do: :elevator_status

  def valid_candidate?(_instance), do: true

  def audio_serialize(_instance), do: %{}

  def audio_sort_key(_instance), do: [0]

  def audio_valid_candidate?(_instance), do: false

  def audio_view(_instance), do: ScreensWeb.V2.Audio.ElevatorStatusView

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.ElevatorStatus

    def priority(instance), do: ElevatorStatus.priority(instance)
    def serialize(instance), do: ElevatorStatus.serialize(instance)
    def slot_names(instance), do: ElevatorStatus.slot_names(instance)
    def widget_type(instance), do: ElevatorStatus.widget_type(instance)
    def valid_candidate?(instance), do: ElevatorStatus.valid_candidate?(instance)
    def audio_serialize(instance), do: ElevatorStatus.audio_serialize(instance)
    def audio_sort_key(instance), do: ElevatorStatus.audio_sort_key(instance)
    def audio_valid_candidate?(instance), do: ElevatorStatus.audio_valid_candidate?(instance)
    def audio_view(instance), do: ElevatorStatus.audio_view(instance)
  end
end
