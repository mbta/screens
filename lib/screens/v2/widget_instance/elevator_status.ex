defmodule Screens.V2.WidgetInstance.ElevatorStatus do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen

  defstruct screen: nil,
            now: nil,
            alerts: nil,
            stop_sequences: nil

  @type stop_id :: String.t()

  @type t :: %__MODULE__{
          screen: Screen.t(),
          now: DateTime.t(),
          alerts: list(Alert.t()),
          stop_sequences: list(list(stop_id()))
        }

  # @max_height_list_container 0
  # @max_height_station_heading 0
  # @max_height_elevator_description 0
  # @max_height_row_separator 0

  defp get_active_at_home_station(
         alerts,
         now,
         parent_station_id
       ) do
    alerts
    |> Enum.filter(&active_at_home_station?(&1, now, parent_station_id))
  end

  defp get_active_elsewhere(
         alerts,
         now,
         parent_station_id,
         stop_sequences
       ) do
    alerts
    |> Enum.filter(&active_elsewhere?(&1, now, parent_station_id))
    |> Enum.sort_by(
      fn %Alert{informed_entities: entities} -> entities end,
      &sort_elsewhere(&1, &2, stop_sequences)
    )
  end

  defp get_upcoming_at_home_station(
         alerts,
         now,
         parent_station_id
       ) do
    alerts
    |> Enum.filter(&upcoming_at_home_station?(&1, now, parent_station_id))
  end

  defp get_upcoming_elsewhere(
         alerts,
         now,
         parent_station_id,
         stop_sequences
       ) do
    alerts
    |> Enum.filter(&upcoming_elsewhere?(&1, now, parent_station_id))
    |> Enum.sort_by(
      fn %Alert{informed_entities: entities} -> entities end,
      &sort_elsewhere(&1, &2, stop_sequences)
    )
  end

  defp active_at_home_station?(
         %Alert{effect: :elevator_closure, informed_entities: entities} = alert,
         now,
         station_id
       ) do
    Alert.happening_now?(alert, now) &&
      Enum.any?(entities, fn entity ->
        entity.stop == station_id
      end)
  end

  defp active_elsewhere?(
         %Alert{effect: :elevator_closure, informed_entities: entities} = alert,
         now,
         parent_station_id
       ) do
    stations = get_stations_from_entities(entities)

    Alert.happening_now?(alert, now) &&
      Enum.any?(stations, fn station ->
        station != parent_station_id
      end)
  end

  defp upcoming_at_home_station?(
         %Alert{effect: :elevator_closure, informed_entities: entities} = alert,
         now,
         station_id
       ) do
    not Alert.happening_now?(alert, now) &&
      Enum.any?(entities, fn entity ->
        entity.stop == station_id
      end)
  end

  defp upcoming_elsewhere?(
         %Alert{effect: :elevator_closure, informed_entities: entities} = alert,
         now,
         parent_station_id
       ) do
    stations = get_stations_from_entities(entities)

    not Alert.happening_now?(alert, now) &&
      Enum.any?(stations, fn station ->
        station != parent_station_id
      end)
  end

  defp sort_elsewhere(e1, _e2, stop_sequences) do
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

  def priority(_instance), do: [2]

  def serialize(_instance) do
    %{}
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
