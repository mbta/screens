defmodule Screens.V2.CandidateGenerator.Dup.Alerts do
  @moduledoc """
  Functions to fetch alert data and convert it to alert widgets for DUP screens.
  """

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.Report
  alias Screens.Stops.Stop
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.WidgetInstance.{DupAlert, DupSpecialCaseAlert}
  alias ScreensConfig.Alerts, as: AlertsConfig
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.Dup

  require Logger

  @doc """
  Fetches alerts + related data from the API and transforms them to candidate
  widgets for a DUP screen.
  """
  def alert_instances(
        config,
        now \\ DateTime.utc_now(),
        fetch_stop_name_fn \\ &Stop.fetch_stop_name/1,
        fetch_alerts_fn \\ &Alert.fetch/1,
        fetch_location_context_fn \\ &LocationContext.fetch/3
      ) do
    # In this function:
    # - Fetch relevant alerts for all SUBWAY/LIGHT RAIL routes serving this stop
    # - Check for special cases. If there is one, just use that. Otherwise:
    # - Select one alert
    # - Create 3 candidate structs from the alert, one for each rotation
    %Screen{app_params: %Dup{alerts: %AlertsConfig{stop_id: stop_id}, header: header_config}} =
      config

    if is_nil(stop_id) do
      []
    else
      stop_name =
        case header_config do
          %{stop_id: stop_id} ->
            case fetch_stop_name_fn.(stop_id) do
              nil -> []
              stop_name -> stop_name
            end

          %{stop_name: stop_name} ->
            stop_name
        end

      with {:ok, location_context} <- fetch_location_context_fn.(Dup, stop_id, now),
           route_ids <- LocationContext.route_ids(location_context),
           {:ok, alerts} <- fetch_alerts_fn.(route_ids: route_ids) do
        alerts
        |> relevant_alerts(config, location_context, now)
        |> alert_special_cases(config)
        |> create_alert_widgets(config, location_context, stop_name)
      else
        :error -> []
      end
    end
  end

  def relevant_alerts(alerts, config, location_context, now) do
    Enum.filter(alerts, fn alert ->
      relevant_effect?(alert, config) and Alert.happening_now?(alert, now) and
        relevant_location?(alert, location_context) and
        not directional_shuttle_or_suspension?(alert)
    end)
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
    |> Enum.min_by(&{effect_key(&1.effect), -&1.severity, -String.to_integer(&1.id)})
    |> tap(fn alert ->
      alert_ids = Enum.map_join(alerts, ",", & &1.id)
      Logger.info("[dup alert selected] selected_id=#{alert.id} all_relevant_ids=#{alert_ids}")
    end)
  end

  defp create_alert_widgets({:special, widgets}, _, _, _), do: widgets

  defp create_alert_widgets({:normal, alerts}, config, location_context, stop_name) do
    alert = choose_alert(alerts)

    if is_nil(alert) do
      []
    else
      for rotation_index <- [:zero, :one, :two] do
        %DupAlert{
          screen: config,
          alert: alert,
          location_context: location_context,
          rotation_index: rotation_index,
          stop_name: stop_name
        }
      end
    end
  end

  defp relevant_effect?(%{effect: :delay, severity: severity}, _) do
    severity >= 5
  end

  # WTC special case
  defp relevant_effect?(%{effect: effect}, %Screen{
         app_params: %Dup{alerts: %AlertsConfig{stop_id: "place-wtcst"}}
       }) do
    effect in [:detour]
  end

  defp relevant_effect?(%{effect: effect}, _) do
    effect in [:station_closure, :shuttle, :suspension]
  end

  @spec relevant_location?(Alert.t(), LocationContext.t()) :: boolean()
  defp relevant_location?(alert, location_context) do
    LocalizedAlert.location(%{alert: alert, location_context: location_context}) in [
      :inside,
      :boundary_upstream,
      :boundary_downstream
    ]
  end

  defp directional_shuttle_or_suspension?(alert) do
    directional =
      alert.effect in [:shuttle, :suspension] and
        not Enum.any?(alert.informed_entities, &is_nil(&1.direction_id))

    if directional do
      Report.warning(
        "dup_discarding_directional_alert",
        alert_id: alert.id,
        alert_effect: alert.effect
      )
    end

    directional
  end

  # If this is a special case, this function returns the widgets that should be used for it.
  # Otherwise, returns the alerts unchanged.
  @spec alert_special_cases(list(Alert.t()), ScreensConfig.Screen.t()) ::
          {:normal, list(Alert.t())} | {:special, list(Screens.V2.WidgetInstance.t())}
  defp alert_special_cases([], _), do: {:normal, []}

  defp alert_special_cases(
         alerts,
         %Screen{app_params: %Dup{alerts: %AlertsConfig{stop_id: stop_id}}}
       ) do
    case stop_id do
      "place-kencl" -> kenmore_special_case(alerts)
      "place-wtcst" -> wtc_special_case(alerts)
      _ -> {:normal, alerts}
    end
  end

  # In the case where Kenmore has 2 or more boundary shuttles / suspensions to the west,
  # don't only select 1 alert; instead look at all alerts and make custom text
  @spec kenmore_special_case(list(Alert.t())) :: {:special, list(Screens.V2.WidgetInstance.t())}
  defp kenmore_special_case(alerts) do
    branches =
      alerts
      |> Enum.filter(fn a -> a.effect === :shuttle end)
      |> Enum.flat_map(
        &get_branches_if_entity_matches_stop(&1, [
          %{branch: "b", stop: "70149"},
          %{branch: "c", stop: "70211"},
          %{branch: "d", stop: "70187"}
        ])
      )
      |> Enum.sort()
      |> Enum.uniq()

    if length(branches) > 1 do
      alert_ids = Enum.map(alerts, fn a -> a.id end)

      {:special,
       [
         %DupSpecialCaseAlert{
           alert_ids: alert_ids,
           widget_type: :partial_alert,
           slot_names: [:bottom_pane_zero],
           branches: branches,
           special_case: :kenmore_westbound_shuttles
         },
         %DupSpecialCaseAlert{
           alert_ids: alert_ids,
           widget_type: :takeover_alert,
           slot_names: [:full_rotation_one],
           branches: branches,
           special_case: :kenmore_westbound_shuttles
         },
         %DupSpecialCaseAlert{
           alert_ids: alert_ids,
           widget_type: :partial_alert,
           slot_names: [:bottom_pane_two],
           branches: branches,
           special_case: :kenmore_westbound_shuttles
         }
       ]}
    else
      {:normal, alerts}
    end
  end

  # In the case where we're at WTC and there's a detour affecting routes SL1/2/3, make custom text
  # Ignore all other SL alerts
  @spec wtc_special_case(list(Alert.t())) :: {:special, list(Screens.V2.WidgetInstance.t())}
  defp wtc_special_case(alerts) do
    alert = choose_alert(alerts)

    detoured_routes =
      alert
      |> Map.get(:informed_entities)
      |> Enum.map(fn entity -> if entity.stop === "place-wtcst", do: entity.route end)
      |> Enum.filter(& &1)
      |> Enum.sort()

    if detoured_routes === ["741", "742", "743", "746"] do
      {:special,
       for rotation_index <- [:full_rotation_zero, :full_rotation_one, :full_rotation_two] do
         %DupSpecialCaseAlert{
           alert_ids: [alert.id],
           widget_type: :takeover_alert,
           slot_names: [rotation_index],
           special_case: :wtc_detour
         }
       end}
    else
      {:normal, []}
    end
  end

  # Given an alert, see if its informed entities match a list of stops-of-interest (called stop_matchers here).
  # If a stop matcher is found, the branch is added the the returned list.
  @spec get_branches_if_entity_matches_stop(
          Alert.t(),
          list(%{branch: String.t(), stop: String.t()})
        ) ::
          [String.t()]
  defp get_branches_if_entity_matches_stop(%{informed_entities: informed_entities}, stop_matchers) do
    stop_matchers
    |> Enum.filter(fn stop ->
      Enum.any?(informed_entities, fn e ->
        stop.stop === e.stop
      end)
    end)
    |> Enum.map(&Map.get(&1, :branch))
  end

  for {effect, key} <- Enum.with_index([:shuttle, :suspension, :station_closure, :detour, :delay]) do
    defp effect_key(unquote(effect)), do: unquote(key)
  end
end
