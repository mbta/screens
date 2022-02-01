defmodule Screens.V2.WidgetInstance.ElevatorStatus do
  @moduledoc false

  defmodule DetailPage do
    @moduledoc false

    alias Screens.V2.WidgetInstance.ElevatorStatus

    @type t :: %__MODULE__{
            header_text: String.t(),
            icons: list(ElevatorStatus.icon()),
            elevator_closure: ElevatorStatus.closure()
          }

    @derive Jason.Encoder

    defstruct header_text: nil,
              icons: nil,
              elevator_closure: nil
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

  # To be replaced by more detailed values for fitting rows in the list view
  @max_rows_per_page 4

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{ElevatorStatus, PreFare}

  defstruct screen: nil,
            now: nil,
            alerts: nil,
            stop_sequences: nil,
            facilities: nil,
            station_id_to_name: nil,
            station_id_to_icons: nil

  @type icon ::
          :red
          | :blue
          | :orange
          | :green
          | :silver
          | :green
          | :rail
          | :bus

  @type timeframe :: %{
          happening_now: boolean(),
          active_period: list()
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
          facilities: list(facility()),
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
    Alert.happening_now?(alert, now) and
      Enum.any?(entities, fn entity ->
        entity.stop == parent_station_id(t)
      end)
  end

  defp active_elsewhere?(
         %Alert{effect: :elevator_closure, informed_entities: entities} = alert,
         %__MODULE__{
           now: now
         } = t
       ) do
    stations = get_stations_from_entities(entities)

    Alert.happening_now?(alert, now) and
      Enum.any?(stations, fn station ->
        station != parent_station_id(t)
      end)
  end

  defp upcoming_at_home_station?(
         %Alert{effect: :elevator_closure, informed_entities: entities} = alert,
         %__MODULE__{now: now} = t
       ) do
    not Alert.happening_now?(alert, now) and
      Enum.any?(entities, fn entity ->
        entity.stop == parent_station_id(t)
      end)
  end

  defp active_on_connecting_lines?(
         %Alert{effect: :elevator_closure, informed_entities: entities} = alert,
         %__MODULE__{now: now, stop_sequences: stop_sequences} = t
       ) do
    stations = get_stations_from_entities(entities)

    Alert.happening_now?(alert, now) and
      Enum.any?(stations, fn station ->
        Enum.any?(stop_sequences, fn stop_sequence ->
          station in stop_sequence and station != parent_station_id(t)
        end)
      end)
  end

  defp sort_elsewhere(e1, _e2, %__MODULE__{stop_sequences: stop_sequences}) do
    stations = get_stations_from_entities(e1)

    Enum.any?(stations, fn station ->
      station in stop_sequences
    end)
  end

  defp get_stations_from_entities(entities) do
    entities
    |> Enum.map(fn %{stop: stop_id} -> stop_id end)
    |> Enum.filter(&String.starts_with?(&1, "place-"))
  end

  defp trim_and_page_alerts(pages) do
    pages
    |> Enum.flat_map(fn
      %ListPage{} = page ->
        split_list_page(page)

      %DetailPage{} = page ->
        [page]
    end)
    |> Enum.take(4)
  end

  defp split_list_page(%ListPage{stations: stations}) do
    stations
    |> Enum.chunk_every(@max_rows_per_page)
    |> Enum.map(&%ListPage{stations: &1})
  end

  defp get_facility_by_id(entities, facilities) do
    facility_in_entity =
      entities
      |> Enum.find_value(fn
        %{facility: facility} -> facility
        _ -> false
      end)

    facilities
    |> Enum.find(fn %{id: id} -> id == facility_in_entity end)
  end

  defp serialize_closure(alert, %{name: name, id: id}, now) do
    %{
      elevator_name: name,
      elevator_id: id,
      timeframe: serialize_timeframe(alert, now),
      description: alert.description
    }
  end

  defp serialize_station(
         {parent_station_id, alerts},
         %__MODULE__{
           facilities: facilities,
           station_id_to_name: station_id_to_name,
           station_id_to_icons: station_id_to_icons,
           now: now
         } = t
       ) do
    station_name = Map.fetch!(station_id_to_name, parent_station_id)

    closures =
      alerts
      |> Enum.map(fn %Alert{
                       informed_entities: entities
                     } = alert ->
        facility = get_facility_by_id(entities, facilities)

        serialize_closure(alert, facility, now)
      end)

    %{
      name: station_name,
      icons: Map.fetch!(station_id_to_icons, parent_station_id),
      elevator_closures: closures,
      is_at_home_stop: parent_station_id == parent_station_id(t)
    }
  end

  defp serialize_timeframe(%Alert{active_period: active_period} = alert, now) do
    %{
      happening_now: Alert.happening_now?(alert, now),
      active_period: Enum.map(active_period, &Alert.ap_to_map/1)
    }
  end

  defp alerts_by_station(alerts) do
    alerts
    |> Enum.map(fn %{informed_entities: informed_entities} = alert ->
      {get_parent_station_id_from_informed_entities(informed_entities), alert}
    end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

    # produces %{parent_station_id => [%Alert{}, ...]}
  end

  defp get_parent_station_id_from_informed_entities(entities) do
    entities
    |> Enum.find_value(fn
      %{stop: "place-" <> _ = parent_station_id} -> parent_station_id
      _ -> false
    end)
  end

  defp serialize_detail_page(
         %Alert{header: header, informed_entities: entities} = alert,
         %__MODULE__{
           station_id_to_icons: station_id_to_icons,
           facilities: facilities,
           now: now
         } = t
       ) do
    facility = get_facility_by_id(entities, facilities)

    %DetailPage{
      header_text: header,
      icons: Map.fetch!(station_id_to_icons, parent_station_id(t)),
      elevator_closure: serialize_closure(alert, facility, now)
    }
  end

  defp serialize_list_page(
         alerts,
         %__MODULE__{} = t
       ) do
    stations =
      alerts
      |> alerts_by_station()
      |> Enum.map(&serialize_station(&1, t))

    %ListPage{
      stations: stations
    }
  end

  def priority(_instance), do: [2]

  @spec serialize(t()) :: %{pages: list(DetailPage.t() | ListPage.t())}
  def serialize(%__MODULE__{} = t) do
    active_at_home =
      t
      |> get_active_at_home_station()
      |> Enum.map(&serialize_detail_page(&1, t))

    active_elsewhere =
      t
      |> get_active_elsewhere()
      |> serialize_list_page(t)

    upcoming_at_home =
      t
      |> get_upcoming_at_home_station()
      |> Enum.map(&serialize_detail_page(&1, t))

    active_on_connecting_lines =
      t
      |> get_active_on_connecting_lines()
      |> Enum.map(&serialize_detail_page(&1, t))

    # first show detail pages for each closure at this station
    # then if there is still space, show list pages for _all_ active closures across the system
    # then if there is still space, show detail pages for upcoming closures at this station
    # then if there is still space, show detail pages for active closures along lines serving this station

    pages =
      [
        active_at_home,
        [active_elsewhere],
        upcoming_at_home,
        active_on_connecting_lines
      ]
      |> Enum.concat()
      |> trim_and_page_alerts()

    %{
      pages: pages
    }
  end

  def slot_names(_instance), do: [:main_content_right]

  def widget_type(_instance), do: :elevator_status

  def valid_candidate?(_instance), do: true

  def audio_serialize(_instance), do: %{}

  def audio_sort_key(_instance), do: 0

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
