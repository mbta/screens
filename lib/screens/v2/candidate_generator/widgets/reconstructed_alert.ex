defmodule Screens.V2.CandidateGenerator.Widgets.ReconstructedAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.Util
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.WidgetInstance.ReconstructedAlert
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Header.CurrentStopId
  alias ScreensConfig.V2.PreFare

  @relevant_effects ~w[shuttle suspension station_closure delay]a

  @doc """
  Given the stop_id defined in the header, determine relevant routes
  Given the routes, fetch all alerts for the route
  """
  def reconstructed_alert_instances(
        %Screen{
          app_params: %PreFare{reconstructed_alert_widget: %CurrentStopId{stop_id: stop_id}}
        } = config,
        now \\ DateTime.utc_now(),
        fetch_alerts_fn \\ &Alert.fetch/1,
        fetch_stop_name_fn \\ &Stop.fetch_stop_name/1,
        fetch_location_context_fn \\ &Stop.fetch_location_context/3
      ) do
    with {:ok, location_context} <- fetch_location_context_fn.(PreFare, stop_id, now),
         route_ids <- Route.route_ids(location_context.routes),
         {:ok, alerts} <- fetch_alerts_fn.(route_ids: route_ids) do
      alerts
      |> relevant_alerts(config, location_context, now)
      |> Enum.map(fn alert ->
        %ReconstructedAlert{
          screen: config,
          alert: alert,
          now: now,
          location_context: location_context,
          informed_stations_string: get_stations(alert, fetch_stop_name_fn),
          is_terminal_station: is_terminal?(stop_id, location_context.stop_sequences)
        }
      end)
    else
      :error -> []
    end
  end

  defp relevant_alerts(alerts, config, location_context, now) do
    Enum.filter(alerts, fn %Alert{effect: effect} = alert ->
      reconstructed_alert = %ReconstructedAlert{
        screen: config,
        alert: alert,
        location_context: location_context,
        now: now,
        informed_stations_string: "A Station"
      }

      relevant_effect?(effect) and relevant_location?(reconstructed_alert) and
        Alert.happening_now?(alert, now)
    end)
  end

  defp relevant_effect?(effect) do
    Enum.member?(@relevant_effects, effect)
  end

  defp relevant_location?(reconstructed_alert) do
    case LocalizedAlert.location(reconstructed_alert) do
      location when location in [:downstream, :upstream] ->
        true

      :inside ->
        relevant_inside_alert?(reconstructed_alert)

      location when location in [:boundary_upstream, :boundary_downstream] ->
        relevant_boundary_alert?(reconstructed_alert)

      _ ->
        false
    end
  end

  defp relevant_inside_alert?(
         %ReconstructedAlert{alert: %Alert{effect: :delay}} = reconstructed_alert
       ),
       do: relevant_delay?(reconstructed_alert)

  defp relevant_inside_alert?(_), do: true

  defp relevant_boundary_alert?(%ReconstructedAlert{alert: %Alert{effect: :station_closure}}),
    do: false

  defp relevant_boundary_alert?(
         %ReconstructedAlert{
           alert: %Alert{effect: :delay}
         } = reconstructed_alert
       ),
       do: relevant_delay?(reconstructed_alert)

  defp relevant_boundary_alert?(_), do: true

  defp relevant_delay?(
         %ReconstructedAlert{alert: %Alert{severity: severity}} = reconstructed_alert
       ) do
    severity > 3 and relevant_direction?(reconstructed_alert)
  end

  # This function assumes that stop_sequences is ordered by direction north/east -> south/west.
  # If the current station's stop_id is the first or last entry in all stop_sequences,
  # it is a terminal station. Delay alerts heading in the direction of the station are not relevant.
  defp relevant_direction?(%ReconstructedAlert{
         alert: alert,
         location_context: %{home_stop: stop_id, stop_sequences: stop_sequences}
       }) do
    informed_entities = Alert.informed_entities(alert)

    direction_id =
      informed_entities
      |> Enum.map(fn %{direction_id: direction_id} -> direction_id end)
      |> Enum.find(fn direction_id -> not is_nil(direction_id) end)

    relevant_direction_for_terminal =
      cond do
        # Alert affects both directions
        is_nil(direction_id) ->
          nil

        # North/East side terminal stations
        Enum.all?(
          stop_sequences,
          fn stop_sequence -> stop_id == List.first(stop_sequence) end
        ) ->
          0

        # South/West side terminal stations
        Enum.all?(
          stop_sequences,
          fn stop_sequence -> stop_id == List.last(stop_sequence) end
        ) ->
          1

        # Single line stations that are not terminal stations
        true ->
          nil
      end

    relevant_direction_for_terminal == nil or relevant_direction_for_terminal == direction_id
  end

  defp get_stations(alert, fetch_stop_name_fn) do
    stop_ids =
      alert
      |> Alert.informed_entities()
      |> Enum.flat_map(fn %{stop: stop_id} ->
        case stop_id do
          nil -> []
          id -> [id]
        end
      end)

    case stop_ids do
      [] ->
        nil

      _ ->
        stop_ids
        |> Enum.filter(&String.starts_with?(&1, "place-"))
        |> Enum.uniq()
        |> Enum.flat_map(
          &case fetch_stop_name_fn.(&1) do
            :error -> []
            name -> [name]
          end
        )
        |> Util.format_name_list_to_string()
    end
  end

  defp is_terminal?(stop_id, stop_sequences) do
    # Can't use Enum.any, because then Govt Center will be seen as a terminal
    # Using all is ok because no station is the terminal of one line and NOT the terminal of another line
    # excluding GL branches
    Enum.all?(stop_sequences, fn stop_sequence ->
      List.first(stop_sequence) == stop_id or List.last(stop_sequence) == stop_id
    end)
  end
end
