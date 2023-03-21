defmodule Screens.V2.CandidateGenerator.Dup.Alerts do
  @moduledoc """
  Functions to fetch alert data and convert it to alert widgets for DUP screens.
  """

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.Alerts, as: AlertsConfig
  alias Screens.Config.V2.Dup
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.Common.BaseAlert
  alias Screens.V2.WidgetInstance.DupAlert

  require Logger

  @doc """
  Fetches alerts + related data from the API and transforms them to candidate
  widgets for a DUP screen.
  """
  def alert_instances(config, now \\ DateTime.utc_now()) do
    # In this function:
    # - Fetch relevant alerts for all SUBWAY/LIGHT RAIL routes serving this stop
    # - Check for special cases. If there is one, just use that. Otherwise:
    # - Select one alert
    # - Create 3 candidate structs from the alert, one for each rotation
    %Screen{app_params: %Dup{alerts: %AlertsConfig{stop_id: stop_id}}} = config

    stop_name = Stop.fetch_stop_name(config.app_params.header.stop_id)

    with {:ok, subway_routes_at_stop} <-
           Route.fetch_routes_by_stop(stop_id, now, [:light_rail, :subway]),
         subway_route_ids_at_stop =
           for(%{route_id: id} <- subway_routes_at_stop, id != "Mattapan", do: id),
         {:ok, alerts} <- Alert.fetch(route_ids: subway_route_ids_at_stop),
         {:ok, stop_sequences} <-
           RoutePattern.fetch_parent_station_sequences_through_stop(
             stop_id,
             subway_route_ids_at_stop
           ) do
      alerts
      |> Enum.filter(&relevant_alert?(&1, config, stop_sequences, subway_routes_at_stop, now))
      |> alert_special_cases(config)
      |> create_alert_widgets(config, stop_sequences, subway_routes_at_stop, stop_name)
    else
      :error -> []
    end
  end

  @doc """
  Chooses the most "important" alert to show on a DUP screen when there are several.

  This function assumes we've already filtered to alerts with relevant effects only.

  When there are multiple relevant alerts, we prioritize first by
  effect (shuttle with highest priority, down to delay with lowest priority),
  then by severity descending, then by alert ID descending.
  """
  @spec choose_alert(list(Alert.t())) :: Alert.t() | nil
  def choose_alert([]), do: nil
  def choose_alert([alert]), do: alert

  def choose_alert(alerts) do
    alerts
    |> Enum.min_by(&{effect_key(&1.effect), -&1.severity, -&1.id})
    |> tap(fn alert ->
      alert_ids = Enum.map_join(alerts, ",", & &1.id)
      Logger.info("[dup alert selected] selected_id=#{alert.id} all_relevant_ids=#{alert_ids}")
    end)
  end

  # Commented out to stop dialyzer from complaining until we fill in relevant logic
  # defp create_alert_widgets({:special, widgets}, _, _, _, _), do: widgets

  defp create_alert_widgets(
         {:normal, alerts},
         config,
         stop_sequences,
         subway_routes_at_stop,
         stop_name
       ) do
    alert = choose_alert(alerts)

    if is_nil(alert) do
      []
    else
      for rotation_index <- [:zero, :one, :two] do
        %DupAlert{
          screen: config,
          alert: alert,
          stop_sequences: stop_sequences,
          subway_routes_at_stop: subway_routes_at_stop,
          rotation_index: rotation_index,
          stop_name: stop_name
        }
      end
    end
  end

  defp relevant_alert?(alert, config, stop_sequences, subway_routes_at_stop, now) do
    dup_alert = %DupAlert{
      screen: config,
      alert: alert,
      stop_sequences: stop_sequences,
      subway_routes_at_stop: subway_routes_at_stop,
      rotation_index: :zero,
      stop_name: "A Station"
    }

    relevant_effect?(alert) and Alert.happening_now?(alert, now) and relevant_location?(dup_alert)
  end

  defp relevant_effect?(%{effect: :delay, severity: severity}) do
    severity >= 5
  end

  defp relevant_effect?(%{effect: effect}) do
    effect in [:station_closure, :shuttle, :suspension]
  end

  defp relevant_location?(dup_alert) do
    BaseAlert.location(dup_alert) in [:inside, :boundary_upstream, :boundary_downstream]
  end

  # If this is a special case, this function returns the widgets that should be used for it.
  # Otherwise, returns the alerts unchanged.
  @spec alert_special_cases(list(Alert.t()), Screens.Config.Screen.t()) ::
          {:normal, list(Alert.t())} | {:special, list(Screens.V2.WidgetInstance.t())}
  defp alert_special_cases(alerts, _config) do
    # Special cases go here!
    # Use the DupSpecialCaseAlert widget to directly specify the serialized data.

    {:normal, alerts}
  end

  for {effect, key} <- Enum.with_index([:shuttle, :suspension, :station_closure, :delay]) do
    defp effect_key(unquote(effect)), do: unquote(key)
  end
end
