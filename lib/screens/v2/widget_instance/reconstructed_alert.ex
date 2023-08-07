defmodule Screens.V2.WidgetInstance.ReconstructedAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.LocationContext
  alias Screens.Stops.Stop
  alias Screens.Util
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.WidgetInstance.ReconstructedAlert
  alias Screens.V2.WidgetInstance.Serializer.RoutePill

  defstruct screen: nil,
            alert: nil,
            now: nil,
            location_context: nil,
            informed_stations: nil,
            is_terminal_station: false,
            is_full_screen: false

  @type stop_id :: String.t()

  @type route_id :: String.t()

  @type t :: %__MODULE__{
          screen: Screen.t(),
          alert: Alert.t(),
          now: DateTime.t(),
          location_context: LocationContext.t(),
          informed_stations: list(String.t()),
          is_terminal_station: boolean(),
          is_full_screen: boolean()
        }

  @type serialized_response ::
          takeover_serialized_response()
          | fullscreen_serialized_response()
          | flex_serialized_response()

  # Values shared in each response
  # %{
  #   issue: String.t(),
  #   cause: String.t(),
  #   effect: Alert.effect()
  # }

  @type takeover_serialized_response :: %{
          optional(:other_closures) => list(String.t()),
          issue: String.t(),
          remedy: String.t(),
          location: String.t(),
          cause: String.t(),
          effect: :suspension | :shuttle | :station_closure,
          updated_at: String.t(),
          routes: list(RoutePill.t())
        }

  @type enriched_route :: %{
          optional(:headsign) => String.t(),
          route_id: String.t(),
          svg_name: String.t()
        }

  @type fullscreen_serialized_response :: %{
          # Unique to fullscreen station closures
          optional(:unaffected_routes) => list(enriched_route()),
          optional(:location) => String.t() | nil,
          optional(:remedy) => String.t(),
          optional(:stations) => list(String.t()),
          # Unique to fullscreen
          optional(:endpoints) => list(String.t()),
          # Unique to transfer station case
          optional(:is_transfer_station) => boolean(),
          issue: String.t() | list(String.t()),
          cause: Alert.cause() | nil,
          # List of SVG filenames
          routes: list(enriched_route()),
          effect: :suspension | :shuttle | :station_closure | :delay,
          updated_at: String.t(),
          # It seems that region was also added to the flex serialized response?
          region: :here | :boundary | :outside
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
    "Copley & West" => "gl-copley-west",
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
      |> hd()
      |> case do
        %{direction_id: nil, route: route} when location == :downstream -> {0, route}
        %{direction_id: nil, route: route} when location == :upstream -> {1, route}
        %{direction_id: direction_id, route: route} -> {direction_id, route}
      end

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
    |> Enum.group_by(&get_line/1)
    |> Enum.map(
      &RoutePill.serialize_route_for_reconstructed_alert(&1, %{
        large: length(affected_routes) == 1
      })
    )
  end

  defp get_route_pills(%__MODULE__{alert: alert} = t, location) do
    informed_entities = Alert.informed_entities(alert)
    routes_at_stop = LocalizedAlert.active_routes_at_stop(t)

    informed_entities
    |> Enum.filter(&(&1.route_type in [0, 1] and &1.route in routes_at_stop))
    |> Enum.group_by(fn %{route: route} -> route end)
    |> Enum.flat_map(fn
      {route_id, _} ->
        headsign = get_destination(t, location, route_id)
        build_pills_from_headsign(route_id, headsign)
    end)
    |> Enum.uniq()
  end

  defp build_pills_from_headsign(route_id, nil) do
    [
      %{
        route_id: get_line(route_id),
        svg_name: format_short_route_pill(route_id)
      }
    ]
  end

  # Split Ashmont/Braintree out into two route pills
  defp build_pills_from_headsign(route_id, "Ashmont/Braintree") do
    Enum.map(["Ashmont", "Braintree"], fn dest ->
      %{
        route_id: route_id,
        svg_name: format_for_svg_name(dest),
        headsign: dest
      }
    end)
  end

  # If headsign is for the trunk, use "Green" as route_id
  defp build_pills_from_headsign(_route_id, headsign)
       when headsign in ["North Station & North", "Copley & West"] do
    [
      %{
        route_id: "Green",
        svg_name: format_for_svg_name(headsign),
        headsign: headsign
      }
    ]
  end

  defp build_pills_from_headsign(route_id, headsign) do
    [
      %{
        route_id: route_id,
        svg_name: format_for_svg_name(headsign),
        headsign: headsign
      }
    ]
  end

  defp get_line("Green" <> _), do: "Green"
  defp get_line(route_id), do: route_id

  defp format_for_svg_name(headsign), do: Map.get(@headsign_svg_map, headsign)

  defp format_cause(:unknown), do: nil
  defp format_cause(cause), do: cause |> to_string() |> String.replace("_", " ")

  defp format_short_route_pill("Green-" <> branch), do: "gl-#{String.downcase(branch)}"

  defp format_short_route_pill(route_id),
    do: route_id |> String.first() |> String.downcase() |> Kernel.<>("l")

  defp get_region_from_location(:inside), do: :here

  defp get_region_from_location(location)
       when location in [:boundary_upstream, :boundary_downstream],
       do: :boundary

  defp get_region_from_location(_location), do: :outside

  defp get_cause(:unknown), do: nil
  defp get_cause(cause), do: cause

  def takeover_alert?(%__MODULE__{is_full_screen: false}), do: false

  def takeover_alert?(%__MODULE__{is_terminal_station: is_terminal_station, alert: alert} = t) do
    Alert.effect(alert) in [:station_closure, :suspension, :shuttle] and
      LocalizedAlert.location(t, is_terminal_station) == :inside and
      LocalizedAlert.informs_all_active_routes_at_home_stop?(t) and
      (is_nil(Alert.direction_id(t.alert)) or is_terminal_station)
  end

  @spec serialize_takeover_alert(t()) :: takeover_serialized_response()
  defp serialize_takeover_alert(t)

  defp serialize_takeover_alert(%__MODULE__{alert: %Alert{effect: :suspension} = alert} = t) do
    %{alert: %{cause: cause, updated_at: updated_at}, now: now} = t
    informed_entities = Alert.informed_entities(alert)

    route_id =
      case LocalizedAlert.informed_subway_routes(t) do
        ["Green" <> _] -> "Green"
        [route_id] -> route_id
      end

    endpoints = get_endpoints(informed_entities, route_id)

    %{
      issue: "No trains",
      remedy: "Seek alternate route",
      location: "No #{route_id} Line trains #{format_endpoint_string(endpoints)}",
      cause: format_cause(cause),
      routes: get_route_pills(t),
      effect: :suspension,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  defp serialize_takeover_alert(%__MODULE__{alert: %Alert{effect: :shuttle} = alert} = t) do
    %{alert: %{cause: cause, updated_at: updated_at}, now: now} = t
    informed_entities = Alert.informed_entities(alert)

    route_id =
      case LocalizedAlert.informed_subway_routes(t) do
        ["Green" <> _] -> "Green"
        [route_id] -> route_id
      end

    endpoints = get_endpoints(informed_entities, route_id)

    %{
      issue: "No trains",
      remedy: "Use shuttle bus",
      location:
        "Shuttle buses replace #{route_id} Line trains #{format_endpoint_string(endpoints)}",
      endpoints: endpoints,
      cause: format_cause(cause),
      routes: get_route_pills(t),
      effect: :shuttle,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  defp serialize_takeover_alert(%__MODULE__{alert: %Alert{effect: :station_closure}} = t) do
    %{
      alert: %{cause: cause, updated_at: updated_at},
      now: now,
      location_context: %{home_stop_name: stop_name},
      informed_stations: informed_stations
    } = t

    informed_stations_string = Util.format_name_list_to_string(informed_stations)

    location_text =
      case LocalizedAlert.informed_subway_routes(t) do
        [route_id] ->
          "#{route_id} Line trains skip #{informed_stations_string}"

        [route_id1, route_id2] ->
          "The #{route_id1} Line and #{route_id2} Line skip #{informed_stations_string}"
      end

    other_closures = List.delete(informed_stations, stop_name)

    %{
      issue: "Station closed",
      remedy: "Seek alternate route",
      location: location_text,
      cause: format_cause(cause),
      routes: get_route_pills(t),
      effect: :station_closure,
      updated_at: format_updated_at(updated_at, now),
      other_closures: other_closures
    }
  end

  @spec serialize_fullscreen_alert(t(), LocalizedAlert.location()) ::
          fullscreen_serialized_response()
  defp serialize_fullscreen_alert(t, location)

  defp serialize_fullscreen_alert(
         %__MODULE__{alert: %Alert{effect: :suspension} = alert} = t,
         location
       ) do
    %{alert: %{cause: cause, updated_at: updated_at}, now: now} = t
    informed_entities = Alert.informed_entities(alert)

    route_id =
      case LocalizedAlert.informed_subway_routes(t) do
        ["Green" <> _] -> "Green"
        [route_id] -> route_id
      end

    endpoints = get_endpoints(informed_entities, route_id)
    destination = get_destination(t, location)

    {issue, location_text} =
      if location in [:downstream, :upstream] do
        {"No trains", nil}
      else
        endpoint_text = format_endpoint_string(endpoints)

        location_text =
          if is_nil(endpoint_text), do: nil, else: "No #{route_id} Line trains #{endpoint_text}"

        issue =
          cond do
            location == :inside ->
              "No #{route_id} Line trains"

            is_nil(destination) ->
              "No trains"

            true ->
              "No trains to #{destination}"
          end

        {issue, location_text}
      end

    %{
      issue: issue,
      remedy: "Seek alternate route",
      location: location_text,
      cause: get_cause(cause),
      routes: get_route_pills(t, location),
      effect: :suspension,
      updated_at: format_updated_at(updated_at, now),
      region: get_region_from_location(location),
      endpoints: endpoints,
      is_transfer_station: location == :inside
    }
  end

  defp serialize_fullscreen_alert(
         %__MODULE__{alert: %Alert{effect: :shuttle} = alert} = t,
         location
       ) do
    %{alert: %{cause: cause, updated_at: updated_at}, now: now} = t
    informed_entities = Alert.informed_entities(alert)

    route_id =
      case LocalizedAlert.informed_subway_routes(t) do
        ["Green" <> _] -> "Green"
        [route_id] -> route_id
      end

    endpoints = get_endpoints(informed_entities, route_id)
    destination = get_destination(t, location)

    {issue, location_text, remedy} =
      if location in [:downstream, :upstream] do
        {"No trains", nil, "Shuttle buses available"}
      else
        endpoint_text = format_endpoint_string(endpoints)
        location_text = if is_nil(endpoint_text), do: nil, else: "Shuttle buses #{endpoint_text}"

        issue =
          cond do
            location == :inside ->
              "No #{route_id} Line trains"

            is_nil(destination) ->
              "No trains"

            true ->
              "No trains to #{destination}"
          end

        {issue, location_text, "Use shuttle bus"}
      end

    %{
      issue: issue,
      remedy: remedy,
      location: location_text,
      cause: get_cause(cause),
      routes: get_route_pills(t, location),
      effect: :shuttle,
      updated_at: format_updated_at(updated_at, now),
      region: get_region_from_location(location),
      endpoints: endpoints,
      is_transfer_station: location == :inside
    }
  end

  # Station closure for 1 line at a multi-line station
  defp serialize_fullscreen_alert(
         %__MODULE__{alert: %Alert{effect: :station_closure}} = t,
         :inside
       ) do
    %{alert: %{cause: cause, updated_at: updated_at}, now: now} = t
    affected_routes = LocalizedAlert.informed_subway_routes(t)
    routes_at_stop = LocalizedAlert.active_routes_at_stop(t)

    unaffected_routes =
      if "Green" in affected_routes do
        Enum.reject(routes_at_stop, &String.starts_with?(&1, "Green-"))
      else
        routes = Enum.into(routes_at_stop, []) -- affected_routes

        if Enum.any?(routes, &String.starts_with?(&1, "Green-")) do
          routes
          |> Enum.reject(&String.starts_with?(&1, "Green-"))
          |> Enum.concat(["Green"])
        else
          routes
        end
      end

    %{
      issue: nil,
      unaffected_routes:
        Enum.flat_map(unaffected_routes, fn route -> build_pills_from_headsign(route, nil) end),
      cause: get_cause(cause),
      routes: get_route_pills(t, :inside),
      effect: :station_closure,
      updated_at: format_updated_at(updated_at, now),
      region: :here
    }
  end

  # Downstream closure
  defp serialize_fullscreen_alert(
         %__MODULE__{alert: %Alert{effect: :station_closure}} = t,
         location
       ) do
    %{
      alert: %{cause: cause, updated_at: updated_at},
      now: now,
      informed_stations: informed_stations
    } = t

    informed_stations_string = Util.format_name_list_to_string(informed_stations)

    %{
      issue: "Trains skip #{informed_stations_string}",
      remedy: "Seek alternate route",
      cause: get_cause(cause),
      routes: get_route_pills(t, location),
      effect: :station_closure,
      updated_at: format_updated_at(updated_at, now),
      region: get_region_from_location(location),
      stations: informed_stations
    }
  end

  defp serialize_fullscreen_alert(
         %__MODULE__{alert: %Alert{effect: :delay}} = t,
         location
       ) do
    %{
      alert: %{cause: cause, updated_at: updated_at, severity: severity, header: header},
      now: now
    } = t

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
      cause: get_cause(cause),
      routes: routes,
      effect: :delay,
      updated_at: format_updated_at(updated_at, now),
      region: get_region_from_location(location)
    }
  end

  defp serialize_inside_flex_alert(
         %__MODULE__{alert: %Alert{effect: :delay, severity: severity}} = t
       )
       when severity > 3 and severity < 7 do
    %{alert: %{header: header}} = t

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

  defp serialize_inside_flex_alert(
         %__MODULE__{alert: %Alert{effect: :delay, severity: severity}} = t
       )
       when severity >= 7 do
    %{alert: %{cause: cause}} = t
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
      routes: get_route_pills(t),
      effect: :severe_delay,
      urgent: true
    }
  end

  @spec serialize_boundary_alert(t(), any()) :: flex_serialized_response()
  defp serialize_boundary_alert(t, location)

  defp serialize_boundary_alert(%__MODULE__{alert: %Alert{effect: :suspension}} = t, location) do
    %{alert: %{cause: cause, header: header}} = t
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

  defp serialize_boundary_alert(%__MODULE__{alert: %Alert{effect: :shuttle}} = t, location) do
    %{alert: %{cause: cause, header: header}} = t
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
         %__MODULE__{alert: %Alert{effect: :delay, severity: severity}} = t,
         _location
       )
       when severity > 3 and severity < 7 do
    %{alert: %{header: header}} = t

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
         %__MODULE__{alert: %Alert{effect: :delay, severity: severity}} = t,
         location
       )
       when severity >= 7 do
    %{alert: %{cause: cause, header: header}} = t
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
         %__MODULE__{alert: %Alert{effect: :suspension} = alert} = t,
         location
       ) do
    %{alert: %{cause: cause, header: header}} = t
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

  defp serialize_outside_alert(%__MODULE__{alert: %Alert{effect: :shuttle} = alert} = t, location) do
    %{alert: %{cause: cause, header: header}} = t
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
         %__MODULE__{alert: %Alert{effect: :station_closure}} = t,
         _location
       ) do
    %{alert: %{cause: cause}, informed_stations: informed_stations} = t
    cause_text = Alert.get_cause_string(cause)

    informed_stations_string = Util.format_name_list_to_string(informed_stations)

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
         %__MODULE__{alert: %Alert{effect: :delay}} = t,
         _location
       ) do
    %{alert: %{header: header}} = t

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
    shifted_updated_at = DateTime.shift_zone!(updated_at, "America/New_York")

    if Date.compare(updated_at, now) == :lt do
      Timex.format!(shifted_updated_at, "{M}/{D}/{YY}")
    else
      Timex.format!(shifted_updated_at, "{WDfull}, {h12}:{m} {am}")
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
      :inside ->
        t |> serialize_inside_flex_alert() |> Map.put(:region, :inside)

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
      else: :single_screen_alert
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

    def audio_view(t),
      do:
        if(ReconstructedAlert.widget_type(t) == :reconstructed_large_alert,
          do: ScreensWeb.V2.Audio.ReconstructedAlertView,
          else: ScreensWeb.V2.Audio.ReconstructedAlertFullscreenView
        )
  end

  defimpl Screens.V2.AlertsWidget do
    def alert_ids(t), do: ReconstructedAlert.alert_ids(t)
  end
end
