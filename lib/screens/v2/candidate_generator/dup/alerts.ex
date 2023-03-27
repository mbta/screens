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
  alias Screens.V2.WidgetInstance.{DupAlert, DupSpecialCaseAlert}

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

    route_type_filter = get_route_type_filter(stop_id)

    with {:ok, subway_routes_at_stop} <-
           Route.fetch_routes_by_stop(stop_id, now, route_type_filter),
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

  # WTC is a special bus-only case
  @spec get_route_type_filter(String.t()) :: list(atom())
  defp get_route_type_filter("place-wtcst"), do: [:bus]
  defp get_route_type_filter(stop_id), do: [:light_rail, :subway]

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

  defp create_alert_widgets({:special, widgets}, _, _, _, _), do: widgets

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

    relevant_effect?(alert, config) and Alert.happening_now?(alert, now) and
      relevant_location?(dup_alert)
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

  defp relevant_location?(dup_alert) do
    BaseAlert.location(dup_alert) in [:inside, :boundary_upstream, :boundary_downstream]
  end

  # If this is a special case, this function returns the widgets that should be used for it.
  # Otherwise, returns the alerts unchanged.
  @spec alert_special_cases(list(Alert.t()), Screens.Config.Screen.t()) ::
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
  def kenmore_special_case(alerts) do
    branches =
      alerts
      |> Enum.filter(fn a -> a.effect === :shuttle end)
      |> Enum.map(
        &get_branch_if_entity_matches_stop(&1, [
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
           serialize_map: %{
             text: %Screens.Config.V2.FreeTextLine{
               icon: :warning,
               text: get_kenmore_special_text(branches, :partial_alert)
             },
             color: :green
           },
           widget_type: :partial_alert,
           slot_names: [:bottom_pane_zero]
         },
         %DupSpecialCaseAlert{
           alert_ids: alert_ids,
           serialize_map: %{
             text: %Screens.Config.V2.FreeTextLine{
               icon: :warning,
               text: get_kenmore_special_text(branches, :takeover_alert)
             },
             header: %{color: :green, text: "Kenmore"},
             remedy: %Screens.Config.V2.FreeTextLine{
               icon: :shuttle,
               text: [%{format: :bold, text: "Use shuttle bus"}]
             }
           },
           widget_type: :takeover_alert,
           slot_names: [:full_rotation_one]
         },
         %DupSpecialCaseAlert{
           alert_ids: alert_ids,
           serialize_map: %{
             text: %Screens.Config.V2.FreeTextLine{
               icon: :warning,
               text: get_kenmore_special_text(branches, :partial_alert)
             },
             color: :green
           },
           widget_type: :partial_alert,
           slot_names: [:bottom_pane_two]
         }
       ]}
    else
      {:normal, alerts}
    end
  end

  # In the case where we're at WTC and there's a detour affecting routes SL1/2/3, make custom text
  # Ignore all other SL alerts
  @spec wtc_special_case(list(Alert.t())) :: {:special, list(Screens.V2.WidgetInstance.t())}
  def wtc_special_case(alerts) do
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
           serialize_map: %{
             text: %Screens.Config.V2.FreeTextLine{
               icon: :warning,
               text: ["Building closed"]
             },
             header: %{color: :silver, text: "World Trade Ctr"},
             remedy: %Screens.Config.V2.FreeTextLine{
               icon: :shuttle,
               text: [%{format: :bold, text: "Board Silver Line on street"}]
             }
           },
           widget_type: :takeover_alert,
           slot_names: [rotation_index]
         }
       end}
    else
      {:normal, []}
    end
  end

  # Given an alert, see if any of its informed entities match a list of stops-of-interest (called stop_matchers here).
  # If it has an informed entity on the list, return its branch.
  @spec get_branch_if_entity_matches_stop(Alert.t(), list(%{branch: String.t(), stop: String.t()})) ::
          atom()
  def get_branch_if_entity_matches_stop(%{informed_entities: informed_entities}, stop_matchers) do
    Enum.find(stop_matchers, fn stop ->
      Enum.any?(informed_entities, fn e ->
        stop.stop === e.stop
      end)
    end)
    |> Map.get(:branch)
  end

  @spec get_kenmore_special_text(list(atom()), atom()) :: list(FreeText.t())
  def get_kenmore_special_text(["b", "c"], :partial_alert),
    do: ["No", %{format: :bold, text: "Bost Coll/Clvlnd Cir"}]

  def get_kenmore_special_text(["b", "c"], :takeover_alert),
    do: [
      "No",
      %{icon: "green_b"},
      %{format: :bold, text: "Bost Coll"},
      "or",
      %{icon: "green_c"},
      %{format: :bold, text: "Cleveland Cir"},
      "trains"
    ]

  def get_kenmore_special_text(["b", "d"], :partial_alert),
    do: ["No", %{format: :bold, text: "Bost Coll / Riverside"}]

  def get_kenmore_special_text(["b", "d"], :takeover_alert),
    do: [
      "No",
      %{icon: "green_b"},
      %{format: :bold, text: "Bost Coll"},
      "or",
      %{icon: "green_d"},
      %{format: :bold, text: "Riverside"},
      "trains"
    ]

  def get_kenmore_special_text(["c", "d"], :partial_alert),
    do: ["No", %{format: :bold, text: "Clvlnd Cir/Riverside"}]

  def get_kenmore_special_text(["c", "d"], :takeover_alert),
    do: [
      "No",
      %{icon: "green_c"},
      %{format: :bold, text: "Cleveland Cir"},
      "or",
      %{icon: "green_d"},
      %{format: :bold, text: "Riverside"},
      "trains"
    ]

  def get_kenmore_special_text(["b", "c", "d"], :partial_alert),
    do: ["No", %{format: :bold, text: "Westbound"}, "trains"]

  def get_kenmore_special_text(["b", "c", "d"], :takeover_alert),
    do: [
      "No",
      %{icon: "green_b"},
      %{icon: "green_c"},
      %{icon: "green_d"},
      %{format: :bold, text: "Westbound"},
      "trains"
    ]

  for {effect, key} <- Enum.with_index([:shuttle, :suspension, :station_closure, :detour, :delay]) do
    defp effect_key(unquote(effect)), do: unquote(key)
  end
end
