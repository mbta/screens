defmodule Screens.V2.WidgetInstance.ElevatorClosures do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Elevator

  defstruct screen: nil,
            alerts: nil,
            location_context: nil,
            now: nil,
            station_id_to_name: nil,
            station_id_to_routes: nil

  @type t :: %__MODULE__{
          screen: Screen.t(),
          alerts: list(Alert.t()),
          location_context: LocationContext.t(),
          now: DateTime.t(),
          station_id_to_name: %{String.t() => String.t()},
          station_id_to_routes: %{String.t() => list(String.t())}
        }

  def serialize(%__MODULE__{
        screen: %Screen{app_params: %Elevator{elevator_id: id}},
        alerts: alerts,
        location_context: location_context,
        station_id_to_name: station_id_to_name,
        station_id_to_routes: station_id_to_routes
      }) do
    {in_station_alerts, outside_alerts} = split_alerts_by_location(alerts, location_context)

    %{
      id: id,
      in_station_alerts:
        serialize_alerts(in_station_alerts, station_id_to_name, station_id_to_routes),
      outside_alerts: serialize_alerts(outside_alerts, station_id_to_name, station_id_to_routes)
    }
  end

  defp split_alerts_by_location(alerts, location_context) do
    Enum.split_with(alerts, fn %Alert{informed_entities: informed_entities} ->
      location_context.home_stop in Enum.map(informed_entities, & &1.stop)
    end)
  end

  defp get_informed_facility(entities) do
    entities
    |> Enum.find_value(fn
      %{facility: facility} -> facility
      _ -> false
    end)
  end

  defp serialize_alerts(alerts, station_id_to_name, station_id_to_routes) do
    alerts
    |> Enum.group_by(&get_parent_station_id_from_informed_entities(&1.informed_entities))
    |> Enum.map(fn {parent_station_id, alerts} ->
      Enum.map(alerts, fn %Alert{
                            id: id,
                            informed_entities: entities,
                            description: description,
                            header: header
                          } ->
        facility = get_informed_facility(entities)

        %{
          station_name: Map.fetch!(station_id_to_name, parent_station_id),
          routes: Map.fetch!(station_id_to_routes, parent_station_id),
          alert_id: id,
          elevator_name: facility.name,
          elevator_id: facility.id,
          description: description,
          header_text: header
        }
      end)
    end)
  end

  defp get_parent_station_id_from_informed_entities(entities) do
    entities
    |> Enum.find_value(fn
      %{stop: "place-" <> _ = parent_station_id} -> parent_station_id
      _ -> false
    end)
  end

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.ElevatorClosures

    def priority(_instance), do: [1]
    def serialize(instance), do: ElevatorClosures.serialize(instance)
    def slot_names(_instance), do: [:main_content]
    def widget_type(_instance), do: :elevator_closures
    def valid_candidate?(_instance), do: true
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.ElevatorClosuresView
  end
end
