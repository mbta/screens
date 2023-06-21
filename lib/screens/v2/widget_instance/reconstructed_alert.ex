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

  @type serialized_response ::
          takeover_serialized_response()
          | fullscreen_serialized_response()
          | flex_serialized_response()

  @type takeover_serialized_response :: %{
          issue: String.t(),
          remedy: String.t(),
          location: String.t(),
          cause: String.t(),
          effect: :suspension | :shuttle | :station_closure,
          updated_at: String.t()
        }

  @type fullscreen_serialized_response :: %{
          optional(:unaffected_routes) => list(route_id()),
          optional(:location) => String.t(),
          optional(:remedy) => String.t(),
          issue: String.t(),
          cause: String.t(),
          routes: list(map() | String.t()),
          effect: :suspension | :shuttle | :station_closure | :delay,
          updated_at: String.t()
        }

  @type flex_serialized_response :: %{
          issue: String.t(),
          remedy: String.t(),
          location: String.t(),
          cause: String.t(),
          routes: list(map() | String.t()),
          effect: :suspension | :shuttle | :station_closure | :delay | :severe_delay,
          urgent: boolean()
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

  @headsign_svg_map %{
    "Bowdoin" => "bl-bowdoin",
    "Wonderland" => "bl-wonderland",
    "Government Center" => "gl-govt-center",
    "North Station & North" => "gl-north-station-north",
    "Boston College" => "glb-boston-college",
    "Cleveland Circle" => "glc-cleveland-cir",
    "Riverside" => "gld-riverside",
    "Union Square" => "gld-union-sq",
    "Heath Street" => "gle-heath-st",
    "Medford/Tufts" => "gle-medford-tufts",
    "Forest Hills" => "ol-forest-hills",
    "Oak Grove" => "ol-oak-grove",
    "Alewife" => "rl-alewife",
    "Ashmont" => "rl-ashmont",
    "Braintree" => "rl-braintree"
  }

  @green_line_branches ["Green-B", "Green-C", "Green-D", "Green-E"]

  # Using hd/1 because we know that only single line stations use this function.
  defp get_destination(
         %__MODULE__{alert: alert} = t,
         location,
         route_id \\ nil
       ) do
    informed_entities =
      if is_nil(route_id) do
        Alert.informed_entities(alert)
      else
        alert |> Alert.informed_entities() |> Enum.filter(&(&1.route == route_id))
      end

    {direction_id, route_id} =
      informed_entities
      |> Enum.map(fn
        %{direction_id: nil, route: route} when location == :downstream -> {0, route}
        %{direction_id: nil, route: route} when location == :upstream -> {1, route}
        %{direction_id: direction_id, route: route} -> {direction_id, route}
      end)
      |> Enum.uniq()
      |> hd()

    cond do
      # When the alert is non-directional but the station is at the boundary:
      # direction_id will be nil, but we still want to show the alert impacts one direction only
      is_nil(direction_id) and location in [:boundary_downstream, :boundary_upstream] ->
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

  defp get_route_pills(t, location \\ nil)

  defp get_route_pills(t, nil) do
    affected_routes = LocalizedAlert.informed_subway_routes(t)

    affected_routes
    |> Enum.group_by(fn
      "Green" <> _ -> "Green"
      route -> route
    end)
    |> Enum.map(
      &RoutePill.serialize_route_for_reconstructed_alert(&1, %{
        large: length(affected_routes) == 1
      })
    )
  end

  defp get_route_pills(%__MODULE__{alert: alert} = t, location) do
    informed_entities = Alert.informed_entities(alert)

    informed_entities
    |> Enum.filter(&(&1.route_type in [0, 1]))
    |> Enum.group_by(fn %{route: route} -> route end)
    |> Enum.map(fn
      {route_id, _} = route ->
        headsign = get_destination(t, location, route_id)

        if is_nil(headsign) do
          RoutePill.serialize_route_for_reconstructed_alert(route)
        else
          format_for_svg_name(headsign)
        end
    end)
    |> Enum.uniq()
  end

  defp format_for_svg_name("Ashmont/Braintree"),
    do: [Map.get(@headsign_svg_map, "Ashmont"), Map.get(@headsign_svg_map, "Braintree")]

  defp format_for_svg_name(headsign), do: Map.get(@headsign_svg_map, headsign)

  def takeover_alert?(%__MODULE__{is_full_screen: false}), do: false

  def takeover_alert?(%__MODULE__{is_terminal_station: is_terminal_station, alert: alert} = t) do
    Alert.effect(alert) in [:station_closure, :suspension, :shuttle] and
      LocalizedAlert.location(t, is_terminal_station) == :inside and
      LocalizedAlert.informs_all_active_routes_at_home_stop?(t) and
      (is_nil(Alert.direction_id(t.alert)) or is_terminal_station)
  end

  @spec serialize_takeover_alert(t()) :: takeover_serialized_response()
  defp serialize_takeover_alert(t)

  defp serialize_takeover_alert(
         %__MODULE__{
           alert: %Alert{effect: :suspension, cause: cause, updated_at: updated_at} = alert,
           now: now
         } = t
       ) do
    informed_entities = Alert.informed_entities(alert)
    cause_text = cause |> Alert.get_cause_string() |> String.capitalize()
    [route_id] = LocalizedAlert.informed_subway_routes(t)
    endpoints = get_endpoints(informed_entities, route_id)

    %{
      issue: "No trains",
      remedy: "Seek alternate route",
      location: "No #{route_id} Line trains #{format_endpoint_string(endpoints)}",
      cause: cause_text,
      effect: :suspension,
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
    cause_text = cause |> Alert.get_cause_string() |> String.capitalize()
    [route_id] = LocalizedAlert.informed_subway_routes(t)
    endpoints = get_endpoints(informed_entities, route_id)

    %{
      issue: "No trains",
      remedy: "Use shuttle bus",
      location:
        "Shuttle buses replace #{route_id} Line trains #{format_endpoint_string(endpoints)}",
      cause: cause_text,
      effect: :shuttle,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  defp serialize_takeover_alert(%__MODULE__{
         alert: %Alert{effect: :station_closure, cause: cause, updated_at: updated_at},
         informed_stations_string: informed_stations_string,
         now: now
       }) do
    cause_text = cause |> Alert.get_cause_string() |> String.capitalize()

    %{
      issue: "Station closed",
      remedy: "Seek alternate route",
      location: "Trains skip #{informed_stations_string}",
      cause: cause_text,
      effect: :station_closure,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  @spec serialize_fullscreen_alert(t(), any()) :: fullscreen_serialized_response()
  defp serialize_fullscreen_alert(t, location)

  defp serialize_fullscreen_alert(
         %__MODULE__{
           alert:
             %Alert{
               effect: :suspension,
               cause: cause,
               updated_at: updated_at
             } = alert,
           now: now
         } = t,
         location
       ) do
    informed_entities = Alert.informed_entities(alert)
    cause_text = Alert.get_cause_string(cause)
    [route_id] = LocalizedAlert.informed_subway_routes(t)
    endpoints = get_endpoints(informed_entities, route_id)
    destination = get_destination(t, location)

    {issue, location_text} =
      if location in [:downstream, :upstream] do
        endpoint_text = format_endpoint_string_as_freetext(endpoints)

        issue =
          FreeTextLine.to_json(%FreeTextLine{
            icon: nil,
            text: [%{format: :bold, text: "No trains"}] ++ endpoint_text
          })

        {issue, ""}
      else
        endpoint_text = format_endpoint_string(endpoints)

        location =
          if is_nil(endpoint_text), do: "", else: "No #{route_id} Line trains #{endpoint_text}"

        issue =
          if is_nil(destination) do
            "No trains"
          else
            "No trains to #{destination}"
          end

        {issue, location}
      end

    %{
      issue: issue,
      remedy: "Seek alternate route",
      location: location_text,
      cause: cause_text,
      routes: get_route_pills(t, location),
      effect: :suspension,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  defp serialize_fullscreen_alert(
         %__MODULE__{
           alert: %Alert{effect: :shuttle, cause: cause, updated_at: updated_at} = alert,
           now: now
         } = t,
         location
       ) do
    informed_entities = Alert.informed_entities(alert)
    cause_text = Alert.get_cause_string(cause)
    [route_id] = LocalizedAlert.informed_subway_routes(t)
    endpoints = get_endpoints(informed_entities, route_id)
    destination = get_destination(t, location)

    {issue, location_text, remedy} =
      if location in [:downstream, :upstream] do
        endpoint_text = format_endpoint_string_as_freetext(endpoints)

        issue =
          FreeTextLine.to_json(%FreeTextLine{
            icon: nil,
            text: [%{format: :bold, text: "No trains"}] ++ endpoint_text
          })

        {issue, "", "Shuttle buses available"}
      else
        endpoint_text = format_endpoint_string(endpoints)
        location_text = if is_nil(endpoint_text), do: "", else: "Shuttle buses #{endpoint_text}"

        issue =
          if is_nil(destination) do
            "No trains"
          else
            "No trains to #{destination}"
          end

        {issue, location_text, "Use shuttle bus"}
      end

    %{
      issue: issue,
      remedy: remedy,
      location: location_text,
      cause: cause_text,
      routes: get_route_pills(t, location),
      effect: :shuttle,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  defp serialize_fullscreen_alert(
         %__MODULE__{
           alert: %Alert{effect: :station_closure, cause: cause, updated_at: updated_at},
           informed_stations_string: informed_stations_string,
           now: now
         } = t,
         location
       ) do
    cause_text = Alert.get_cause_string(cause)

    %{
      issue: "Trains skip #{informed_stations_string}",
      remedy: "Seek alternate route",
      cause: cause_text,
      routes: get_route_pills(t, location),
      effect: :station_closure,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  defp serialize_fullscreen_alert(
         %__MODULE__{
           alert: %Alert{
             effect: :delay,
             cause: cause,
             severity: severity,
             updated_at: updated_at,
             header: header
           },
           now: now
         } = t,
         location
       ) do
    cause_text = Alert.get_cause_string(cause)
    {delay_description, delay_minutes} = Alert.interpret_severity(severity)
    affected_routes = LocalizedAlert.informed_subway_routes(t)

    duration_text =
      case delay_description do
        :up_to -> "up to #{delay_minutes} minutes"
        :more_than -> "over #{delay_minutes} minutes"
      end

    routes =
      if length(affected_routes) > 1 do
        []
      else
        get_route_pills(t, location)
      end

    %{
      issue: "Trains may be delayed #{duration_text}",
      remedy: header,
      cause: cause_text,
      routes: routes,
      effect: :delay,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  @spec serialize_boundary_alert(t(), any()) :: flex_serialized_response()
  defp serialize_boundary_alert(t, location)

  defp serialize_boundary_alert(
         %__MODULE__{
           alert: %Alert{
             effect: :suspension,
             cause: cause,
             header: header
           }
         } = t,
         location
       ) do
    affected_routes = LocalizedAlert.informed_subway_routes(t)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        remedy: "Seek alternate route",
        location: "",
        cause: "",
        routes: get_route_pills(t),
        effect: :suspension,
        urgent: true
      }
    else
      destination = get_destination(t, location)
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
        routes: get_route_pills(t),
        effect: :suspension,
        urgent: true
      }
    end
  end

  defp serialize_boundary_alert(
         %__MODULE__{
           alert: %Alert{effect: :shuttle, cause: cause, header: header}
         } = t,
         location
       ) do
    affected_routes = LocalizedAlert.informed_subway_routes(t)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        remedy: "Use shuttle bus",
        location: "",
        cause: "",
        routes: get_route_pills(t),
        effect: :shuttle,
        urgent: true
      }
    else
      destination = get_destination(t, location)
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
        routes: get_route_pills(t),
        effect: :shuttle,
        urgent: true
      }
    end
  end

  defp serialize_boundary_alert(%__MODULE__{alert: %Alert{effect: :station_closure}}, _location),
    do: nil

  defp serialize_boundary_alert(
         %__MODULE__{
           alert: %Alert{
             effect: :delay,
             severity: severity,
             header: header
           }
         } = t,
         _location
       )
       when severity > 3 and severity < 7 do
    %{
      issue: header,
      remedy: "",
      location: "",
      cause: "",
      routes: get_route_pills(t),
      effect: :delay,
      urgent: false
    }
  end

  defp serialize_boundary_alert(
         %__MODULE__{
           alert: %Alert{
             effect: :delay,
             cause: cause,
             severity: severity,
             header: header
           }
         } = t,
         location
       )
       when severity >= 7 do
    affected_routes = LocalizedAlert.informed_subway_routes(t)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        remedy: "",
        location: "",
        cause: "",
        routes: get_route_pills(t),
        effect: :severe_delay,
        urgent: true
      }
    else
      cause_text = Alert.get_cause_string(cause)
      {delay_description, delay_minutes} = Alert.interpret_severity(severity)
      destination = get_destination(t, location)

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
        routes: get_route_pills(t),
        effect: :severe_delay,
        urgent: true
      }
    end
  end

  defp serialize_boundary_alert(%__MODULE__{alert: %Alert{effect: :delay}}, _location), do: nil

  @spec serialize_outside_alert(t(), any()) :: flex_serialized_response()
  defp serialize_outside_alert(t, location)

  defp serialize_outside_alert(
         %__MODULE__{
           alert: %Alert{effect: :suspension, cause: cause, header: header} = alert
         } = t,
         location
       ) do
    informed_entities = Alert.informed_entities(alert)
    affected_routes = LocalizedAlert.informed_subway_routes(t)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        remedy: "Seek alternate route",
        location: "",
        cause: "",
        routes: get_route_pills(t),
        effect: :suspension,
        urgent: false
      }
    else
      direction_id = Alert.direction_id(alert)
      cause_text = Alert.get_cause_string(cause)

      location_text =
        informed_entities |> get_endpoints(hd(affected_routes)) |> format_endpoint_string()

      issue =
        if is_nil(direction_id) do
          "No trains"
        else
          "No #{get_destination(t, location)} trains"
        end

      %{
        issue: issue,
        remedy: "Seek alternate route",
        location: location_text,
        cause: cause_text,
        routes: get_route_pills(t),
        effect: :suspension,
        urgent: false
      }
    end
  end

  defp serialize_outside_alert(
         %__MODULE__{
           alert: %Alert{effect: :shuttle, cause: cause, header: header} = alert
         } = t,
         location
       ) do
    informed_entities = Alert.informed_entities(alert)
    affected_routes = LocalizedAlert.informed_subway_routes(t)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        remedy: "Use shuttle bus",
        location: "",
        cause: "",
        routes: get_route_pills(t),
        effect: :suspension,
        urgent: false
      }
    else
      direction_id = Alert.direction_id(alert)
      cause_text = Alert.get_cause_string(cause)

      location_text =
        informed_entities |> get_endpoints(hd(affected_routes)) |> format_endpoint_string()

      issue =
        if is_nil(direction_id) do
          "No trains"
        else
          "No #{get_destination(t, location)} trains"
        end

      %{
        issue: issue,
        remedy: "Use shuttle bus",
        location: location_text,
        cause: cause_text,
        routes: get_route_pills(t),
        effect: :shuttle,
        urgent: false
      }
    end
  end

  defp serialize_outside_alert(
         %__MODULE__{
           alert: %Alert{effect: :station_closure, cause: cause},
           informed_stations_string: informed_stations_string
         } = t,
         _location
       ) do
    cause_text = Alert.get_cause_string(cause)

    %{
      issue: "Trains will bypass #{informed_stations_string}",
      remedy: "Seek alternate route",
      location: "",
      cause: cause_text,
      routes: get_route_pills(t),
      effect: :station_closure,
      urgent: false
    }
  end

  defp serialize_outside_alert(
         %__MODULE__{
           alert: %Alert{effect: :delay, header: header}
         } = t,
         _location
       ) do
    %{
      issue: header,
      remedy: "",
      location: "",
      cause: "",
      routes: get_route_pills(t),
      effect: :delay,
      urgent: false
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

        {min_full_name, max_full_name}
    end
  end

  def format_endpoint_string(nil), do: nil

  def format_endpoint_string({min_station, max_station}) do
    if min_station == max_station do
      "at #{min_station}"
    else
      "between #{min_station} and #{max_station}"
    end
  end

  def format_endpoint_string_as_freetext(endpoints) do
    case endpoints do
      nil ->
        []

      {min, max} when min == max ->
        [" at ", %{format: :bold, text: min}]

      {min, max} ->
        [" between ", %{format: :bold, text: min}, " & ", %{format: :bold, text: max}]
    end
  end

  def serialize(%__MODULE__{is_full_screen: true} = t) do
    if takeover_alert?(t) do
      serialize_takeover_alert(t)
    else
      location = LocalizedAlert.location(t)
      serialize_fullscreen_alert(t, location)
    end
  end

  def serialize(%__MODULE__{is_terminal_station: is_terminal_station} = t) do
    case LocalizedAlert.location(t, is_terminal_station) do
      location when location in [:boundary_upstream, :boundary_downstream] ->
        t |> serialize_boundary_alert(location) |> Map.put(:region, :boundary)

      location when location in [:downstream, :upstream] ->
        t |> serialize_outside_alert(location) |> Map.put(:region, :outside)
    end
  end

  def audio_sort_key(%__MODULE__{is_full_screen: true}), do: [2]

  def audio_sort_key(%__MODULE__{} = t) do
    case serialize(t) do
      %{urgent: true} -> [2]
      %{effect: effect} when effect in [:delay] -> [2, 2]
      _ -> [2, 1]
    end
  end

  def priority(%__MODULE__{is_full_screen: true}), do: [1]
  def priority(_t), do: [3]

  def slot_names(%__MODULE__{is_full_screen: false}), do: [:large]

  def slot_names(%__MODULE__{} = t) do
    if takeover_alert?(t),
      do: [:full_body],
      else: [:paged_main_content_left]
  end

  def widget_type(%__MODULE__{is_full_screen: false}), do: :reconstructed_large_alert

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
