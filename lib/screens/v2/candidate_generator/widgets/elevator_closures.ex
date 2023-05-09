defmodule Screens.V2.CandidateGenerator.Widgets.ElevatorClosures do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{ElevatorStatus, PreFare}
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.ElevatorStatus, as: ElevatorStatusWidget

  def elevator_status_instances(
        %Screen{
          app_params: %PreFare{
            elevator_status: %ElevatorStatus{parent_station_id: parent_station_id}
          }
        } = config,
        now \\ DateTime.utc_now(),
        fetch_location_context_fn \\ &Stop.fetch_location_context/3
      ) do
    with location_context <- fetch_location_context_fn.(PreFare, parent_station_id, now),
         {:ok, parent_station_map} <- Stop.fetch_parent_station_name_map(),
         {:ok, elevator_closures, facility_id_to_name} <- fetch_elevator_closures() do
      icon_map = get_icon_map(elevator_closures, parent_station_id)

      [
        %ElevatorStatusWidget{
          # TODO: put anything else into location context?
          alerts: elevator_closures,
          location_context: location_context,
          facility_id_to_name: facility_id_to_name,
          screen: config,
          now: now,
          station_id_to_name: parent_station_map,
          station_id_to_icons: icon_map
        }
      ]
    else
      :error -> []
    end
  end

  def fetch_elevator_closures do
    case Screens.V3Api.get_json("alerts", %{
           "filter[activity]" => "USING_WHEELCHAIR",
           "include" => "facilities"
         }) do
      {:ok, result} ->
        facilities =
          result
          |> get_in([
            "included",
            Access.filter(&(&1["type"] == "facility"))
          ])
          |> parse_facility_data()

        elevator_closures =
          result
          |> Screens.Alerts.Parser.parse_result()
          |> Enum.filter(fn
            %Alert{effect: :elevator_closure} = alert -> alert
            _ -> false
          end)

        {:ok, elevator_closures, facilities}

      _ ->
        :error
    end
  end

  defp get_icon_map(elevator_closures, home_parent_station_id) do
    elevator_closures
    |> get_parent_station_ids_from_entities()
    |> MapSet.new()
    |> MapSet.put(home_parent_station_id)
    |> Enum.map(fn station_id ->
      {station_id, station_id |> Stop.create_station_with_routes_map() |> routes_to_icons()}
    end)
    |> Enum.into(%{})
  end

  defp get_parent_station_ids_from_entities(alerts) do
    alerts
    |> Enum.flat_map(fn %Alert{informed_entities: informed_entities} ->
      informed_entities
      |> Enum.map(fn %{stop: stop_id} -> stop_id end)
      |> Enum.filter(&String.starts_with?(&1, "place-"))
    end)
  end

  defp routes_to_icons(routes) do
    routes
    |> Enum.map(fn
      %Screens.Routes.Route{type: :subway, id: id} -> id |> String.downcase() |> String.to_atom()
      %Screens.Routes.Route{type: :light_rail, id: "Green-" <> _} -> :green
      %Screens.Routes.Route{type: :light_rail, id: "Mattapan" <> _} -> :mattapan
      %Screens.Routes.Route{type: :bus, short_name: "SL" <> _} -> :silver
      %Screens.Routes.Route{type: type} -> type
    end)
    |> Enum.uniq()
  end

  defp parse_facility_data(nil), do: %{}

  defp parse_facility_data(facilities) do
    facilities
    |> Enum.map(fn %{"attributes" => %{"short_name" => short_name}, "id" => id} ->
      {id, short_name}
    end)
    |> Enum.into(%{})
  end
end
