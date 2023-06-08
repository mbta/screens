defmodule Screens.V2.WidgetInstance.ReconstructedAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.FreeTextLine
  alias Screens.LocationContext
  alias Screens.Stops.Stop
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.WidgetInstance.ReconstructedAlert
  alias Screens.V2.WidgetInstance.Serializer.RoutePill

  defstruct screen: nil,
            alert: nil,
            now: nil,
            location_context: nil,
            informed_stations_string: nil,
            is_terminal_station: false,
            is_full_screen: false

  @type stop_id :: String.t()

  @type route_id :: String.t()

  @type t :: %__MODULE__{
          screen: Screen.t(),
          alert: Alert.t(),
          now: DateTime.t(),
          location_context: LocationContext.t(),
          informed_stations_string: String.t(),
          is_terminal_station: boolean(),
          is_full_screen: boolean()
        }

  @type serialized_response :: %{
          issue: String.t(),
          remedy: String.t(),
          location: String.t(),
          cause: String.t(),
          routes: list(map()),
          effect: :suspension | :shuttle | :station_closure | :delay,
          urgent: boolean(),
          updated_at: String.t()
        }

  @route_directions %{
    "Blue" => ["Bowdoin", "Wonderland"],
    "Orange" => ["Forest Hills", "Oak Grove"],
    "Red" => ["Ashmont/Braintree", "Alewife"],
    "Green-B" => ["Boston College", "Government Center"],
    "Green-C" => ["Cleveland Circle", "Government Center"],
    "Green-D" => ["Riverside", "North Station"],
    "Green-E" => ["Heath Street", "Union Square"]
  }

  @green_line_branches ["Green-B", "Green-C", "Green-D", "Green-E"]

  # Using hd/1 because we know that only single line stations use this function.
  defp get_destination(%{alert: alert} = t, location) do
    informed_entities = Alert.informed_entities(alert)

    {direction_id, route_id} =
      informed_entities
      |> Enum.map(fn %{direction_id: direction_id, route: route} -> {direction_id, route} end)
      |> Enum.uniq()
      |> hd()

    cond do
      # When the alert is non-directional but the station is at the boundary:
      # direction_id will be nil, but we still want to show the alert impacts one direction only
      is_nil(direction_id) and location == :boundary ->
        LocalizedAlert.get_headsign_from_informed_entities(t)

      # When the alert is non-directional and the station is outside the alert range
      is_nil(direction_id) ->
        nil

      # Otherwise, direction is provided, and we can find the destination tag from @route_directions
      true ->
        @route_directions
        |> Map.get(route_id)
        |> Enum.at(direction_id)
    end
  end

  defp get_route_pills(informed_entities) do
    informed_entities
    |> Enum.filter(&(&1.route_type in [0, 1]))
    |> Enum.group_by(fn
      %{route: "Green" <> _, direction_id: direction_id} -> {"Green", direction_id}
      %{route: route, direction_id: direction_id} -> {route, direction_id}
    end)
    |> Enum.map(
      &RoutePill.serialize_route_for_reconstructed_alert(&1, %{
        large: length(informed_entities) == 1
      })
    )
  end

  def takeover_alert?(%__MODULE__{is_full_screen: false}), do: false

  def takeover_alert?(%__MODULE__{is_terminal_station: is_terminal_station, alert: alert} = t) do
    Alert.effect(alert) in [:station_closure, :suspension, :shuttle] and
      LocalizedAlert.location(t, is_terminal_station) == :inside and
      LocalizedAlert.informs_all_active_routes_at_home_stop?(t)
  end

  @spec serialize_takeover_alert(t()) :: serialized_response()
  defp serialize_takeover_alert(t)

  defp serialize_takeover_alert(
         %__MODULE__{
           alert: %Alert{effect: :suspension, cause: cause, updated_at: updated_at} = alert,
           now: now
         } = t
       ) do
    informed_entities = Alert.informed_entities(alert)
    affected_routes = LocalizedAlert.informed_subway_routes(t)
    cause_text = cause |> Alert.get_cause_string() |> String.capitalize()

    location_text = get_endpoints(informed_entities, hd(affected_routes))

    issue = %FreeTextLine{
      icon: nil,
      text:
        ["No"] ++
          (affected_routes
           |> Enum.map(fn route ->
             %{
               route:
                 route
                 |> String.replace("-", "_")
                 |> String.downcase()
             }
           end)
           |> Enum.to_list()) ++
          ["trains"]
    }

    %{
      issue: FreeTextLine.to_json(issue),
      remedy: "Seek alternate route",
      location: location_text,
      cause: cause_text,
      routes: get_route_pills(informed_entities),
      effect: :suspension,
      urgent: true,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  defp serialize_takeover_alert(
         %__MODULE__{
           alert: %Alert{effect: :shuttle, cause: cause, updated_at: updated_at} = alert,
           now: now
         } = t
       ) do
    informed_entities = Alert.informed_entities(alert)
    affected_routes = LocalizedAlert.informed_subway_routes(t)
    cause_text = cause |> Alert.get_cause_string() |> String.capitalize()

    location_text = get_endpoints(informed_entities, hd(affected_routes))

    issue = %FreeTextLine{
      icon: nil,
      text:
        ["No"] ++
          (affected_routes
           |> Enum.map(fn route ->
             %{
               route:
                 route
                 |> String.replace("-", "_")
                 |> String.downcase()
             }
           end)
           |> Enum.to_list()) ++
          ["trains"]
    }

    %{
      issue: FreeTextLine.to_json(issue),
      remedy: "Use shuttle bus",
      location: location_text,
      cause: cause_text,
      routes: get_route_pills(informed_entities),
      effect: :shuttle,
      urgent: true,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  defp serialize_takeover_alert(%__MODULE__{
         alert: %Alert{effect: :station_closure, cause: cause, updated_at: updated_at} = alert,
         now: now
       }) do
    informed_entities = Alert.informed_entities(alert)
    cause_text = cause |> Alert.get_cause_string() |> String.capitalize()

    %{
      issue: "Station Closed",
      remedy: "Seek alternate route",
      location: "",
      cause: cause_text,
      routes: get_route_pills(informed_entities),
      effect: :station_closure,
      urgent: true,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  @spec serialize_fullscreen_alert(t()) :: serialized_response()
  defp serialize_fullscreen_alert(t)

  defp serialize_fullscreen_alert(
         %__MODULE__{
           alert:
             %Alert{
               effect: :suspension,
               cause: cause,
               updated_at: updated_at
             } = alert,
           now: now
         } = t
       ) do
    informed_entities = Alert.informed_entities(alert)
    cause_text = Alert.get_cause_string(cause)
    direction_id = Alert.direction_id(alert)
    [route_id] = LocalizedAlert.informed_subway_routes(t)

    headsign =
      @route_directions
      |> Map.get(route_id)
      |> Enum.at(direction_id)

    issue =
      if is_nil(headsign) do
        "No trains"
      else
        "No trains to #{headsign}"
      end

    %{
      issue: issue,
      remedy: "Seek alternate route",
      location: "",
      cause: cause_text,
      routes: get_route_pills(informed_entities),
      effect: :suspension,
      urgent: true,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  defp serialize_fullscreen_alert(%__MODULE__{
         alert: %Alert{effect: :shuttle, cause: cause, updated_at: updated_at} = alert,
         now: now
       }) do
    informed_entities = Alert.informed_entities(alert)
    cause_text = Alert.get_cause_string(cause)

    %{
      issue: "No trains",
      remedy: "Use shuttle bus",
      location: "",
      cause: cause_text,
      routes: get_route_pills(informed_entities),
      effect: :shuttle,
      urgent: true,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  defp serialize_fullscreen_alert(
         %__MODULE__{
           alert: %Alert{effect: :station_closure, cause: cause, updated_at: updated_at} = alert,
           now: now
         } = t
       ) do
    informed_entities = Alert.informed_entities(alert)
    affected_routes = LocalizedAlert.informed_subway_routes(t)
    cause_text = Alert.get_cause_string(cause)

    line =
      case affected_routes do
        ["Green-" <> branch | _] -> "Green Line #{branch} branch"
        [affected_line | _] -> "#{affected_line} line"
      end

    %{
      issue: "#{line} platform closed",
      remedy: "Seek alternate route",
      location: "",
      cause: cause_text,
      routes: get_route_pills(informed_entities),
      effect: :station_closure,
      urgent: true,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  defp serialize_fullscreen_alert(
         %__MODULE__{
           alert:
             %Alert{effect: :delay, cause: cause, severity: severity, updated_at: updated_at} =
               alert,
           now: now
         } = t
       ) do
    informed_entities = Alert.informed_entities(alert)
    cause_text = Alert.get_cause_string(cause)
    {delay_description, delay_minutes} = Alert.interpret_severity(severity)
    destination = get_destination(t, :inside)

    duration_text =
      case delay_description do
        :up_to -> "up to #{delay_minutes} minutes"
        :more_than -> "over #{delay_minutes} minutes"
      end

    # Even if the screen is "inside" the alert range, the alert itself can
    # still be one-directional. (Only westbound / eastbound is impacted)
    issue =
      if is_nil(destination) do
        "Trains may be delayed #{duration_text}"
      else
        "#{destination} trains may be delayed #{duration_text}"
      end

    %{
      issue: issue,
      remedy: "",
      location: "",
      cause: cause_text,
      routes: get_route_pills(informed_entities),
      effect: :severe_delay,
      urgent: true,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  @spec serialize_boundary_alert(t()) :: serialized_response()
  defp serialize_boundary_alert(t)

  defp serialize_boundary_alert(
         %__MODULE__{
           alert:
             %Alert{
               effect: :suspension,
               cause: cause,
               header: header,
               updated_at: updated_at
             } = alert,
           now: now
         } = t
       ) do
    informed_entities = Alert.informed_entities(alert)
    affected_routes = LocalizedAlert.informed_subway_routes(t)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        remedy: "Seek alternate route",
        location: "",
        cause: "",
        routes: get_route_pills(informed_entities),
        effect: :suspension,
        urgent: true,
        updated_at: format_updated_at(updated_at, now)
      }
    else
      destination = get_destination(t, :boundary)
      cause_text = Alert.get_cause_string(cause)

      issue =
        if is_nil(destination) do
          "No trains"
        else
          "No #{destination} trains"
        end

      %{
        issue: issue,
        remedy: "Seek alternate route",
        location: "",
        cause: cause_text,
        routes: get_route_pills(informed_entities),
        effect: :suspension,
        urgent: true,
        updated_at: format_updated_at(updated_at, now)
      }
    end
  end

  defp serialize_boundary_alert(
         %__MODULE__{
           alert:
             %Alert{effect: :shuttle, cause: cause, header: header, updated_at: updated_at} =
               alert,
           now: now
         } = t
       ) do
    informed_entities = Alert.informed_entities(alert)
    affected_routes = LocalizedAlert.informed_subway_routes(t)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        remedy: "Use shuttle bus",
        location: "",
        cause: "",
        routes: get_route_pills(informed_entities),
        effect: :shuttle,
        urgent: true,
        updated_at: format_updated_at(updated_at, now)
      }
    else
      destination = get_destination(t, :boundary)
      cause_text = Alert.get_cause_string(cause)

      issue =
        if is_nil(destination) do
          "No trains"
        else
          "No #{destination} trains"
        end

      %{
        issue: issue,
        remedy: "Use shuttle bus",
        location: "",
        cause: cause_text,
        routes: get_route_pills(informed_entities),
        effect: :shuttle,
        urgent: true,
        updated_at: format_updated_at(updated_at, now)
      }
    end
  end

  defp serialize_boundary_alert(%__MODULE__{alert: %Alert{effect: :station_closure}}), do: nil

  defp serialize_boundary_alert(%__MODULE__{
         alert:
           %Alert{
             effect: :delay,
             severity: severity,
             header: header,
             updated_at: updated_at
           } = alert,
         now: now
       })
       when severity > 3 and severity < 7 do
    informed_entities = Alert.informed_entities(alert)

    %{
      issue: header,
      remedy: "",
      location: "",
      cause: "",
      routes: get_route_pills(informed_entities),
      effect: :delay,
      urgent: false,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  defp serialize_boundary_alert(
         %__MODULE__{
           alert:
             %Alert{
               effect: :delay,
               cause: cause,
               severity: severity,
               header: header,
               updated_at: updated_at
             } = alert,
           now: now
         } = t
       )
       when severity >= 7 do
    informed_entities = Alert.informed_entities(alert)
    affected_routes = LocalizedAlert.informed_subway_routes(t)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        remedy: "",
        location: "",
        cause: "",
        routes: get_route_pills(informed_entities),
        effect: :severe_delay,
        urgent: true,
        updated_at: format_updated_at(updated_at, now)
      }
    else
      cause_text = Alert.get_cause_string(cause)
      {delay_description, delay_minutes} = Alert.interpret_severity(severity)
      destination = get_destination(t, :boundary)

      duration_text =
        case delay_description do
          :up_to -> "up to #{delay_minutes} minutes"
          :more_than -> "over #{delay_minutes} minutes"
        end

      issue =
        if is_nil(destination) do
          "Trains may be delayed #{duration_text}"
        else
          "#{destination} trains may be delayed #{duration_text}"
        end

      %{
        issue: issue,
        remedy: "",
        location: "",
        cause: cause_text,
        routes: get_route_pills(informed_entities),
        effect: :severe_delay,
        urgent: true,
        updated_at: format_updated_at(updated_at, now)
      }
    end
  end

  defp serialize_boundary_alert(%__MODULE__{alert: %Alert{effect: :delay}}), do: nil

  @spec serialize_outside_alert(t()) :: serialized_response()
  defp serialize_outside_alert(t)

  defp serialize_outside_alert(
         %__MODULE__{
           alert:
             %Alert{effect: :suspension, cause: cause, header: header, updated_at: updated_at} =
               alert,
           now: now
         } = t
       ) do
    informed_entities = Alert.informed_entities(alert)

    affected_routes = LocalizedAlert.informed_subway_routes(t)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        remedy: "Seek alternate route",
        location: "",
        cause: "",
        routes: get_route_pills(informed_entities),
        effect: :suspension,
        urgent: false,
        updated_at: format_updated_at(updated_at, now)
      }
    else
      destination = get_destination(t, :outside)
      cause_text = Alert.get_cause_string(cause)
      location_text = get_endpoints(informed_entities, hd(affected_routes))

      issue =
        if is_nil(destination) do
          "No trains"
        else
          "No #{destination} trains"
        end

      %{
        issue: issue,
        remedy: "Seek alternate route",
        location: location_text,
        cause: cause_text,
        routes: get_route_pills(informed_entities),
        effect: :suspension,
        urgent: false,
        updated_at: format_updated_at(updated_at, now)
      }
    end
  end

  defp serialize_outside_alert(
         %__MODULE__{
           alert:
             %Alert{effect: :shuttle, cause: cause, header: header, updated_at: updated_at} =
               alert,
           now: now
         } = t
       ) do
    informed_entities = Alert.informed_entities(alert)

    affected_routes = LocalizedAlert.informed_subway_routes(t)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        remedy: "Use shuttle bus",
        location: "",
        cause: "",
        routes: get_route_pills(informed_entities),
        effect: :suspension,
        urgent: false,
        updated_at: format_updated_at(updated_at, now)
      }
    else
      destination = get_destination(t, :outside)
      cause_text = Alert.get_cause_string(cause)
      location_text = get_endpoints(informed_entities, List.first(affected_routes))

      issue =
        if is_nil(destination) do
          "No trains"
        else
          "No #{destination} trains"
        end

      %{
        issue: issue,
        remedy: "Use shuttle bus",
        location: location_text,
        cause: cause_text,
        routes: get_route_pills(informed_entities),
        effect: :shuttle,
        urgent: false,
        updated_at: format_updated_at(updated_at, now)
      }
    end
  end

  defp serialize_outside_alert(%__MODULE__{
         alert: %Alert{effect: :station_closure, cause: cause, updated_at: updated_at} = alert,
         informed_stations_string: informed_stations_string,
         now: now
       }) do
    informed_entities = Alert.informed_entities(alert)

    cause_text = Alert.get_cause_string(cause)

    %{
      issue: "Trains will bypass #{informed_stations_string}",
      remedy: "Seek alternate route",
      location: "",
      cause: cause_text,
      routes: get_route_pills(informed_entities),
      effect: :station_closure,
      urgent: false,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  defp serialize_outside_alert(%__MODULE__{
         alert: %Alert{effect: :delay, header: header, updated_at: updated_at} = alert,
         now: now
       }) do
    informed_entities = Alert.informed_entities(alert)

    %{
      issue: header,
      remedy: "",
      location: "",
      cause: "",
      routes: get_route_pills(informed_entities),
      effect: :delay,
      urgent: false,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  defp format_updated_at(updated_at, now) do
    if Date.compare(updated_at, now) == :lt do
      Timex.format!(updated_at, "{M}/{D}/{YY}")
    else
      Timex.format!(updated_at, "{WDfull}, {h12}:{m} {am}")
    end
  end

  def get_endpoints(ie, "Green") do
    Enum.find_value(@green_line_branches, fn branch ->
      get_endpoints(ie, branch)
    end)
  end

  def get_endpoints(informed_entities, route_id) do
    case Stop.get_stop_sequence(informed_entities, route_id) do
      nil ->
        nil

      stop_sequence ->
        {min_index, max_index} =
          informed_entities
          |> Enum.filter(&Stop.stop_on_route?(&1.stop, stop_sequence))
          |> Enum.map(&Stop.to_stop_index(&1, stop_sequence))
          |> Enum.min_max()

        {_, min_station_name} = Enum.at(stop_sequence, min_index)
        {_, max_station_name} = Enum.at(stop_sequence, max_index)

        {min_full_name, _min_abbreviated_name} = min_station_name
        {max_full_name, _max_abbreviated_name} = max_station_name

        if min_full_name == max_full_name do
          "at #{min_full_name}"
        else
          "between #{min_full_name} and #{max_full_name}"
        end
    end
  end

  def serialize(%__MODULE__{is_full_screen: true} = t) do
    if takeover_alert?(t) do
      serialize_takeover_alert(t)
    else
      serialize_fullscreen_alert(t)
    end
  end

  def serialize(%__MODULE__{is_terminal_station: is_terminal_station} = t) do
    case LocalizedAlert.location(t, is_terminal_station) do
      location when location in [:boundary_upstream, :boundary_downstream] ->
        t |> serialize_boundary_alert() |> Map.put(:region, :boundary)

      location when location in [:downstream, :upstream] ->
        t |> serialize_outside_alert() |> Map.put(:region, :outside)
    end
  end

  def audio_sort_key(%__MODULE__{} = t) do
    case serialize(t) do
      %{urgent: true} -> [2]
      %{effect: effect} when effect in [:delay] -> [2, 2]
      _ -> [2, 1]
    end
  end

  def priority(%__MODULE__{} = t) do
    if takeover_alert?(t), do: [1], else: [3]
  end

  def slot_names(%__MODULE__{is_full_screen: false}), do: [:large]

  def slot_names(%__MODULE__{} = t) do
    if takeover_alert?(t),
      do: [:full_body],
      else: [:paged_main_content_left]
  end

  def widget_type(%__MODULE__{is_full_screen: false}), do: [:reconstructed_large_alert]

  def widget_type(%__MODULE__{} = t) do
    if takeover_alert?(t),
      do: :reconstructed_takeover,
      else: :reconstructed_full_body_alert
  end

  def alert_ids(%__MODULE__{} = t), do: [t.alert.id]

  def temporarily_override_alert(%__MODULE__{} = t) do
    # Prevent Porter and Charles/MGH pre-fare screens from incorrectly communicating
    # a RL alert that affects both the Ashmont and Braintree branches.
    not (t.alert.id == "495153" and
           t.screen.app_params.reconstructed_alert_widget.stop_id in [
             "place-portr",
             "place-chmnl"
           ])
  end

  defimpl Screens.V2.WidgetInstance do
    def priority(t), do: ReconstructedAlert.priority(t)
    def serialize(t), do: ReconstructedAlert.serialize(t)
    def slot_names(t), do: ReconstructedAlert.slot_names(t)
    def widget_type(t), do: ReconstructedAlert.widget_type(t)
    def valid_candidate?(t), do: ReconstructedAlert.temporarily_override_alert(t)
    def audio_serialize(t), do: ReconstructedAlert.serialize(t)
    def audio_sort_key(t), do: ReconstructedAlert.audio_sort_key(t)
    def audio_valid_candidate?(t), do: ReconstructedAlert.temporarily_override_alert(t)
    def audio_view(_instance), do: ScreensWeb.V2.Audio.ReconstructedAlertView
  end

  defimpl Screens.V2.AlertsWidget do
    def alert_ids(t), do: ReconstructedAlert.alert_ids(t)
  end
end
