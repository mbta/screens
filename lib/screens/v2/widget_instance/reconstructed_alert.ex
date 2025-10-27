defmodule Screens.V2.WidgetInstance.ReconstructedAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Alerts.InformedEntity
  alias Screens.LocationContext
  alias Screens.Report
  alias Screens.Routes.Route
  alias Screens.Stops.{Stop, Subway}
  alias Screens.Util
  alias Screens.V2.DisruptionDiagram
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.WidgetInstance.ReconstructedAlert
  alias Screens.V2.WidgetInstance.Serializer.RoutePill
  alias ScreensConfig.{Departures, FreeText, FreeTextLine, Screen}
  alias ScreensConfig.Screen.PreFare

  defstruct screen: nil,
            alert: nil,
            now: nil,
            location_context: nil,
            home_station_name: nil,
            informed_station_names: [],
            is_terminal_station: false,
            is_priority: false,
            partial_closure_platform_names: []

  @type stop_id :: String.t()

  @type route_id :: String.t()

  @type t :: %__MODULE__{
          screen: Screen.t(),
          alert: Alert.t(),
          now: DateTime.t(),
          location_context: LocationContext.t(),
          home_station_name: String.t() | nil,
          informed_station_names: list(String.t()),
          is_terminal_station: boolean(),
          is_priority: boolean(),
          partial_closure_platform_names: list(String.t())
        }

  @type serialized_response ::
          dual_screen_serialized_response()
          | single_screen_serialized_response()
          | flex_serialized_response()

  @type dual_screen_serialized_response :: %{
          optional(:disruption_diagram) => DisruptionDiagram.serialized_response(),
          optional(:other_closures) => list(String.t()),
          issue: String.t(),
          remedy: String.t(),
          location: String.t() | FreeTextLine.t(),
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

  @type effect :: :suspension | :shuttle | :station_closure | :delay | :information
  @type region :: :here | :boundary | :outside

  @type single_screen_serialized_response :: %{
          optional(:disruption_diagram) => DisruptionDiagram.serialized_response(),
          # Unique to station closures
          optional(:unaffected_routes) => list(enriched_route()),
          optional(:location) => String.t() | nil,
          optional(:remedy) => String.t() | nil,
          optional(:stations) => list(String.t()),
          # Unique to single screen alerts
          optional(:endpoints) => list(String.t()),
          # Unique to transfer station case
          optional(:is_transfer_station) => boolean(),
          issue: String.t() | list(String.t()) | nil,
          cause: Alert.cause() | nil,
          # List of SVG filenames
          routes: list(enriched_route()),
          effect: effect(),
          updated_at: String.t(),
          region: region()
        }

  @type flex_serialized_response :: %{
          region: region(),
          issue: String.t(),
          remedy: String.t(),
          location: String.t(),
          cause: String.t(),
          routes: list(map() | String.t()),
          effect: effect(),
          urgent: boolean()
        }

  @route_directions %{
    "Blue" => ["Bowdoin", "Wonderland"],
    "Orange" => ["Forest Hills", "Oak Grove"],
    "Red-Ashmont" => ["Ashmont", "Alewife"],
    "Red-Braintree" => ["Braintree", "Alewife"],
    "Red" => ["Ashmont & Braintree", "Alewife"],
    "Green-B" => ["Boston College", "Government Center"],
    "Green-C" => ["Cleveland Circle", "Government Center"],
    "Green-D" => ["Riverside", "Union Square"],
    "Green-E" => ["Heath Street", "Medford/Tufts"],
    "Green-trunk" => ["Copley & West", "North Station & North"],
    "Mattapan" => ["Mattapan", "Ashmont"]
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
    "Braintree" => "rl-braintree",
    "Mattapan" => "rl-mattapan"
  }

  @green_line_branches ["Green-B", "Green-C", "Green-D", "Green-E"]

  defp get_destination(
         %__MODULE__{alert: %Alert{effect: effect, informed_entities: informed_entities}} = t,
         location,
         route_id \\ nil
       ) do
    relevant_ies =
      Enum.filter(informed_entities, fn entity ->
        (InformedEntity.parent_station?(entity) or is_nil(entity.stop)) and
          (is_nil(route_id) or String.starts_with?(entity.route, route_id))
      end)

    # Consolidate the list of entities into their direction from current station
    # and their affiliated route id
    list_of_directions_and_routes =
      relevant_ies
      |> Enum.map(&get_direction_and_route_from_entity(&1, effect, location))
      |> Enum.filter(& &1)
      |> Enum.uniq()

    {direction_id, route_id} = select_direction_and_route(list_of_directions_and_routes)

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

  # Given an entity and the directionality of the alert from the home stop,
  # return a tuple with the affected direction_id and route_id

  defp get_direction_and_route_from_entity(%{stop: "place-jfk"}, :station_closure, _location),
    do: {nil, "Red"}

  # Skip processing JFK, because it is a branching node station. The other stations in the alert
  # will determine the destination needed for this alert
  defp get_direction_and_route_from_entity(%{stop: "place-jfk"}, _, _location),
    do: nil

  # If the route is red and the alert is downstream, we have to figure out whether the alert
  # only affects one branch or both
  defp get_direction_and_route_from_entity(
         %{direction_id: nil, route: "Red", stop: stop_id},
         _,
         location
       )
       when stop_id != nil and location in [:downstream, :boundary_downstream] do
    cond do
      Subway.ashmont_branch_stop?(stop_id) ->
        {0, "Red-Ashmont"}

      Subway.braintree_branch_stop?(stop_id) ->
        {0, "Red-Braintree"}

      true ->
        {0, "Red"}
    end
  end

  # Same with RL upstream alerts
  defp get_direction_and_route_from_entity(
         %{direction_id: nil, route: "Red", stop: stop_id},
         _,
         location
       )
       when stop_id != nil and location in [:upstream, :boundary_upstream] do
    cond do
      Subway.ashmont_branch_stop?(stop_id) ->
        {1, "Red-Ashmont"}

      Subway.braintree_branch_stop?(stop_id) ->
        {1, "Red-Braintree"}

      true ->
        {1, "Red"}
    end
  end

  defp get_direction_and_route_from_entity(%{direction_id: nil, route: route}, _, location)
       when location in [:downstream, :boundary_downstream],
       do: {0, route}

  defp get_direction_and_route_from_entity(%{direction_id: nil, route: route}, _, location)
       when location in [:upstream, :boundary_upstream],
       do: {1, route}

  defp get_direction_and_route_from_entity(%{direction_id: direction_id, route: route}, _, _),
    do: {direction_id, route}

  # Select 1 direction + route from this list of directions + routes for multiple branches
  defp select_direction_and_route([]), do: {nil, nil}
  defp select_direction_and_route([direction_and_route]), do: direction_and_route

  # If there are multiple route ids in that informed entities list, then the alert includes branching
  defp select_direction_and_route([{direction_id, "Red" <> _} | _]), do: {direction_id, "Red"}
  defp select_direction_and_route([{direction_id, _} | _]), do: {direction_id, "Green-trunk"}

  defp get_route_pills(t, location \\ nil)

  defp get_route_pills(t, nil) do
    affected_routes = LocalizedAlert.consolidated_informed_subway_routes(t)

    affected_routes
    |> Enum.group_by(&get_line/1)
    |> Enum.map(
      &RoutePill.serialize_route_for_reconstructed_alert(&1, %{
        large: length(affected_routes) == 1
      })
    )
  end

  defp get_route_pills(%__MODULE__{} = t, location) do
    affected_routes = LocalizedAlert.consolidated_informed_subway_routes(t)
    routes_at_stop = LocalizedAlert.active_routes_at_stop(t)

    affected_routes
    # Filter alert-affected routes by which routes are at the current stop
    # If a green-branch is the affected route, we can generalize it to just "Green-"
    # because our prefare screens will be on the trunk. Any GL disruption will be
    # downstream of a GL trunk station.
    |> Enum.filter(fn
      "Green" <> _ -> Enum.find(routes_at_stop, &String.starts_with?(&1, "Green"))
      route -> route in routes_at_stop
    end)
    |> Enum.flat_map(fn
      route_id ->
        # Boundary alerts shouldn't have headsign in the banner
        headsign =
          unless get_region_from_location(location) === :boundary do
            get_destination(t, location, route_id)
          end

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

  # Split "Ashmont & Braintree" out into two route pills
  defp build_pills_from_headsign(route_id, "Ashmont & Braintree") do
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

  defp format_cause(cause, capitalize \\ false)
  defp format_cause(:unknown, _), do: nil
  defp format_cause(cause, false), do: cause |> to_string() |> String.replace("_", " ")
  defp format_cause(cause, true), do: cause |> format_cause(false) |> String.capitalize()

  defp format_short_route_pill("Green-" <> branch), do: "gl-#{String.downcase(branch)}"

  defp format_short_route_pill(route_id),
    do: route_id |> String.first() |> String.downcase() |> Kernel.<>("l")

  # Alert subheaders should not wrap in the middle of a station name
  # so we have to use FreeTextLines to prevent the wrapping.
  # This function takes a list of proper noun strings and
  # returns a list of FreeTextLines with "nowrap" applied
  @spec format_station_name_list([String.t()]) :: list(FreeText.t())
  defp format_station_name_list([string]), do: [%{format: :nowrap, text: "#{string}"}]

  defp format_station_name_list([s1, s2]),
    do: [
      %{format: :nowrap, text: "#{s1}"},
      " & ",
      %{format: :nowrap, text: "#{s2}"}
    ]

  defp format_station_name_list(list) do
    list
    |> List.update_at(-1, &" & #{&1}")
    |> Enum.join(", #")
    |> String.split("#")
    |> Enum.map(fn string -> %{format: :nowrap, text: string} end)
    |> Enum.intersperse("")
  end

  defp get_region_from_location(:inside), do: :here

  defp get_region_from_location(location)
       when location in [:boundary_upstream, :boundary_downstream],
       do: :boundary

  defp get_region_from_location(_location), do: :outside

  defp get_cause(:unknown), do: nil
  defp get_cause(cause), do: cause

  defp placement(
         %__MODULE__{
           is_terminal_station: is_terminal_station,
           screen: %Screen{app_params: %PreFare{departures: departures, template: template}}
         } = t
       ) do
    has_departures = match?(%Departures{sections: [_ | _]}, departures)
    location = LocalizedAlert.location(t, is_terminal_station)
    t |> base_placement(location) |> adjust_placement(location, template, has_departures)
  end

  defp base_placement(
         %__MODULE__{
           alert: %Alert{effect: effect} = alert,
           is_priority: true,
           is_terminal_station: is_terminal_station,
           partial_closure_platform_names: []
         } = t,
         location
       )
       when effect in [:station_closure, :suspension, :shuttle] do
    if location == :inside and
         LocalizedAlert.informs_all_active_routes_at_home_stop?(t) and
         (is_nil(Alert.direction_id(alert)) or is_terminal_station),
       do: :dual_screen,
       else: :single_screen
  end

  defp base_placement(%__MODULE__{is_priority: true}, _location), do: :single_screen
  defp base_placement(%__MODULE__{}, _location), do: :flex_zone

  # When departures are enabled, downgrade single-screen takeovers to the flex zone
  defp adjust_placement(:single_screen, _location, :duo, true), do: :flex_zone
  defp adjust_placement(placement, _location, :duo, _has_departures), do: placement
  # "Downgrade" placement by one level for solo screens, with some exceptions.
  defp adjust_placement(:dual_screen, _location, :solo, _), do: :single_screen
  defp adjust_placement(:single_screen, :inside, :solo, _), do: :single_screen
  defp adjust_placement(:single_screen, _location, :solo, _), do: :flex_zone
  defp adjust_placement(:flex_zone, _location, :solo, _), do: :flex_zone

  # Two screen alert, suspension
  defp dual_screen_fields(%__MODULE__{alert: %Alert{effect: :suspension}} = t) do
    %__MODULE__{
      alert: %Alert{cause: cause, informed_entities: informed_entities, updated_at: updated_at},
      location_context: %LocationContext{home_stop: home_stop},
      now: now
    } = t

    route_id =
      case LocalizedAlert.consolidated_informed_subway_routes(t) do
        ["Green" <> _] -> "Green"
        [route_id] -> route_id
      end

    endpoints = get_endpoints(informed_entities, route_id, home_stop)

    %{
      issue: "No trains",
      remedy: "Seek alternate route",
      location: "No #{route_id} Line trains #{format_endpoint_string(endpoints)}",
      endpoints: endpoints,
      cause: format_cause(cause),
      routes: get_route_pills(t),
      effect: :suspension,
      updated_at: format_updated_at(updated_at, now)
    }
  end

  # Two screen alert, shuttle
  defp dual_screen_fields(%__MODULE__{alert: %Alert{effect: :shuttle}} = t) do
    %__MODULE__{
      alert: %Alert{cause: cause, informed_entities: informed_entities, updated_at: updated_at},
      location_context: %LocationContext{home_stop: home_stop},
      now: now
    } = t

    route_id =
      case LocalizedAlert.consolidated_informed_subway_routes(t) do
        ["Green" <> _] -> "Green"
        [route_id] -> route_id
      end

    endpoints = get_endpoints(informed_entities, route_id, home_stop)

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

  # Two screen alert, station closure
  defp dual_screen_fields(%__MODULE__{alert: %Alert{effect: :station_closure}} = t) do
    %__MODULE__{
      alert: %{cause: cause, updated_at: updated_at},
      now: now,
      home_station_name: home_station_name,
      informed_station_names: informed_station_names
    } = t

    # Alert subheaders should not wrap in the middle of a station name
    # so we have to use FreeTextLines to prevent the wrapping
    informed_stations_free_text = format_station_name_list(informed_station_names)

    location_text =
      case LocalizedAlert.consolidated_informed_subway_routes(t) do
        [route_id] ->
          %FreeTextLine{
            icon: nil,
            text: ["#{route_id} Line trains skip "] ++ informed_stations_free_text
          }

        [route_id1, route_id2] ->
          %FreeTextLine{
            icon: nil,
            text:
              ["The #{route_id1} Line and #{route_id2} Line skip "] ++ informed_stations_free_text
          }
      end

    other_closures = List.delete(informed_station_names, home_station_name)

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

  # Fallback for when we're unable to build a disruption diagram
  defp dual_screen_fallback_fields(%__MODULE__{alert: alert, now: now} = t) do
    %{
      issue: if(alert.effect == :station_closure, do: "Station closed", else: "No trains"),
      remedy: if(alert.effect == :shuttle, do: "Use shuttle bus", else: "Seek alternate route"),
      location: alert.header,
      cause: format_cause(alert.cause),
      routes: get_route_pills(t),
      effect: alert.effect,
      updated_at: format_updated_at(alert.updated_at, now)
    }
  end

  defp single_screen_fields(%__MODULE__{alert: %Alert{effect: :suspension}} = t, location) do
    %__MODULE__{
      alert: %Alert{cause: cause, informed_entities: informed_entities, updated_at: updated_at},
      location_context: %LocationContext{home_stop: home_stop},
      now: now
    } = t

    route_id =
      case LocalizedAlert.consolidated_informed_subway_routes(t) do
        ["Green" <> _] -> "Green"
        [route_id] -> route_id
      end

    endpoints = get_endpoints(informed_entities, route_id, home_stop)
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
            # Here
            location == :inside ->
              "No #{route_id} Line trains"

            is_nil(destination) ->
              "No trains"

            # Boundary
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

  defp single_screen_fields(%__MODULE__{alert: %Alert{effect: :shuttle}} = t, location) do
    %__MODULE__{
      alert: %Alert{cause: cause, informed_entities: informed_entities, updated_at: updated_at},
      location_context: %LocationContext{home_stop: home_stop},
      now: now
    } = t

    route_id =
      case LocalizedAlert.consolidated_informed_subway_routes(t) do
        ["Green" <> _] -> "Green"
        [route_id] -> route_id
      end

    endpoints = get_endpoints(informed_entities, route_id, home_stop)
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

  # Partial closure - single platform, single direction
  defp single_screen_fields(
         %__MODULE__{
           alert: %Alert{
             effect: :station_closure
           },
           partial_closure_platform_names: [informed_platform_name]
         } = t,
         location
       ) do
    %__MODULE__{
      alert: %{cause: cause, updated_at: updated_at, header: header},
      now: now,
      informed_station_names: informed_station_names
    } = t

    region = get_region_from_location(location)

    issue =
      if region == :here do
        "#{informed_platform_name} platform closed"
      else
        "#{Util.format_name_list_to_string(informed_station_names)}: Trains skip #{informed_platform_name} platform"
      end

    %{
      issue: issue,
      remedy: header,
      cause: get_cause(cause),
      routes: get_route_pills(t, location),
      effect: :station_closure,
      updated_at: format_updated_at(updated_at, now),
      region: region,
      stations: informed_station_names
    }
  end

  # Partial closure, but multiple platforms - use fallback fields
  defp single_screen_fields(
         %__MODULE__{
           alert: %Alert{
             effect: :station_closure
           },
           partial_closure_platform_names: informed_platform_names
         } = t,
         location
       )
       when informed_platform_names != [] do
    single_screen_fallback_fields(t, location)
  end

  # This station closed for entire/only route
  defp single_screen_fields(%__MODULE__{alert: %Alert{effect: :station_closure}} = t, :inside) do
    %__MODULE__{alert: %{cause: cause, updated_at: updated_at}, now: now} = t
    affected_routes = LocalizedAlert.consolidated_informed_subway_routes(t)
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
      issue: if(unaffected_routes == [], do: "Station closed"),
      remedy: if(unaffected_routes == [], do: "Seek alternate route"),
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
  defp single_screen_fields(%__MODULE__{alert: %Alert{effect: :station_closure}} = t, location) do
    %__MODULE__{
      alert: %{cause: cause, updated_at: updated_at},
      now: now,
      informed_station_names: informed_station_names
    } = t

    informed_stations_string = Util.format_name_list_to_string(informed_station_names)

    %{
      issue: "Trains skip #{informed_stations_string}",
      remedy: "Seek alternate route",
      cause: get_cause(cause),
      routes: get_route_pills(t, location),
      effect: :station_closure,
      updated_at: format_updated_at(updated_at, now),
      region: get_region_from_location(location),
      stations: informed_station_names
    }
  end

  defp single_screen_fields(%__MODULE__{alert: %Alert{effect: :delay}} = t, location) do
    %__MODULE__{
      alert:
        %Alert{cause: cause, severity: severity, updated_at: updated_at, header: header} = alert,
      now: now
    } = t

    issue =
      if severity == 1,
        do: format_cause(cause, true),
        else: "Trains may be delayed #{Alert.delay_description(alert)}"

    routes =
      case LocalizedAlert.consolidated_informed_subway_routes(t) do
        [_single] -> get_route_pills(t, location)
        _multiple -> []
      end

    %{
      issue: issue,
      remedy: header,
      cause: if(severity == 1, do: nil, else: get_cause(cause)),
      routes: routes,
      effect: if(severity == 1, do: :information, else: :delay),
      updated_at: format_updated_at(updated_at, now),
      region: get_region_from_location(location)
    }
  end

  # Fallback for when we're unable to build a disruption diagram
  defp single_screen_fallback_fields(%__MODULE__{alert: alert, now: now} = t, location) do
    %{
      issue:
        case alert.effect do
          :shuttle -> "Shuttle Bus"
          :suspension -> "Suspension"
          :station_closure -> "Stop Skipped"
          :delay -> "Delay"
        end,
      remedy: alert.header,
      location: nil,
      cause: format_cause(alert.cause),
      routes: get_route_pills(t, location),
      effect: alert.effect,
      updated_at: format_updated_at(alert.updated_at, now),
      region: get_region_from_location(location)
    }
  end

  # Special case for informational alerts; currently intended only for single-tracking but may
  # work acceptably with other "causes"
  defp flex_zone_fields(%__MODULE__{alert: %Alert{severity: 1}} = t, location) do
    %__MODULE__{
      alert: %Alert{cause: cause, informed_entities: informed_entities},
      location_context: %LocationContext{home_stop: home_stop}
    } = t

    affected_routes = LocalizedAlert.consolidated_informed_subway_routes(t)

    location_text =
      informed_entities
      |> get_endpoints(hd(affected_routes), home_stop)
      |> format_endpoint_string()

    if length(affected_routes) > 1 or is_nil(location_text) do
      flex_zone_fallback_fields(t, location, false)
    else
      %{
        issue: format_cause(cause, true),
        remedy: "",
        location: "",
        cause: location_text,
        routes: get_route_pills(t),
        effect: :information,
        urgent: false,
        region: get_region_from_location(location)
      }
    end
  end

  defp flex_zone_fields(%__MODULE__{alert: %Alert{effect: effect}} = t, location)
       when location in ~w[inside boundary_upstream boundary_downstream]a and
              effect in ~w[delay shuttle suspension]a do
    %__MODULE__{alert: %Alert{severity: severity} = alert} = t
    affected_routes = LocalizedAlert.consolidated_informed_subway_routes(t)

    if length(affected_routes) > 1 do
      flex_zone_fallback_fields(t, location, effect != :delay or severity >= 7)
    else
      destination = get_destination(t, location)

      issue =
        case effect do
          :delay ->
            delay_description = Alert.delay_description(alert)

            if is_nil(destination),
              do: "Trains may be delayed #{delay_description}",
              else: "#{destination} trains may be delayed #{delay_description}"

          _other ->
            if is_nil(destination), do: "No trains", else: "No #{destination} trains"
        end

      remedy =
        case effect do
          :delay -> ""
          :shuttle -> "Use shuttle bus"
          :suspension -> "Seek alternate route"
        end

      %{
        issue: issue,
        remedy: remedy,
        location: "",
        cause: cause_description(alert),
        routes: get_route_pills(t),
        effect: effect,
        urgent: effect != :delay or severity >= 7,
        region: get_region_from_location(location)
      }
    end
  end

  defp flex_zone_fields(%__MODULE__{alert: %Alert{effect: effect}} = t, location)
       when location in ~w[upstream downstream]a and effect in ~w[delay shuttle suspension]a do
    %__MODULE__{
      alert: %Alert{informed_entities: informed_entities} = alert,
      location_context: %LocationContext{home_stop: home_stop}
    } = t

    affected_routes = LocalizedAlert.consolidated_informed_subway_routes(t)

    location_text =
      informed_entities
      |> get_endpoints(hd(affected_routes), home_stop)
      |> format_endpoint_string()

    if is_nil(location_text) or length(affected_routes) > 1 do
      flex_zone_fallback_fields(t, location, false)
    else
      issue =
        case effect do
          :delay ->
            delay_description = Alert.delay_description(alert)

            if Alert.direction_id(alert),
              do: "#{get_destination(t, location)} trains may be delayed #{delay_description}",
              else: "Trains may be delayed #{delay_description}"

          _other ->
            if Alert.direction_id(alert),
              do: "No #{get_destination(t, location)} trains",
              else: "No trains"
        end

      remedy =
        case effect do
          :delay -> ""
          :shuttle -> "Use shuttle bus"
          :suspension -> "Seek alternate route"
        end

      %{
        issue: issue,
        remedy: remedy,
        location: location_text,
        cause: cause_description(alert),
        routes: get_route_pills(t),
        effect: effect,
        urgent: false,
        region: get_region_from_location(location)
      }
    end
  end

  # Partial closure
  defp flex_zone_fields(
         %__MODULE__{
           alert: %Alert{effect: :station_closure},
           informed_station_names: [informed_station],
           partial_closure_platform_names: partial_closure_platform_names
         } = t,
         location
       )
       when partial_closure_platform_names != [] do
    issue =
      case partial_closure_platform_names do
        [informed_platform_name] ->
          "#{informed_station}: Trains skip #{informed_platform_name} platform"

        informed_subway_platforms ->
          Cldr.Message.format!("Skipping {num_platforms, plural,
            =1 {1 platform}
            other {# platforms}} at {informed_station}",
            num_platforms: length(informed_subway_platforms),
            informed_station: informed_station
          )
      end

    %{
      issue: issue,
      remedy: nil,
      location: "",
      cause: nil,
      routes: get_route_pills(t),
      effect: :station_closure,
      urgent: location == :inside,
      region: get_region_from_location(location)
    }
  end

  # Full closure
  defp flex_zone_fields(%__MODULE__{alert: %Alert{effect: :station_closure}} = t, location) do
    %__MODULE__{alert: alert, informed_station_names: informed_station_names} = t

    informed_stations_string = Util.format_name_list_to_string(informed_station_names)

    %{
      issue: "Trains will skip #{informed_stations_string}",
      remedy: "Seek alternate route",
      location: "",
      cause: cause_description(alert),
      routes: get_route_pills(t),
      effect: :station_closure,
      urgent: false,
      region: get_region_from_location(location)
    }
  end

  defp flex_zone_fallback_fields(
         %__MODULE__{alert: %Alert{effect: effect, header: header}} = t,
         location,
         is_urgent
       ) do
    %{
      issue: header,
      remedy: "",
      location: "",
      cause: "",
      routes: get_route_pills(t),
      effect: effect,
      urgent: is_urgent,
      region: get_region_from_location(location)
    }
  end

  defp format_updated_at(updated_at, now) do
    local_updated_at = Util.to_eastern(updated_at)

    if Date.compare(updated_at, now) == :lt do
      Timex.format!(local_updated_at, "{M}/{D}/{YY}")
    else
      Timex.format!(local_updated_at, "{WDfull}, {h12}:{m} {am}")
    end
  end

  defp abbreviate_station_name("Massachusetts Avenue"), do: "Mass Ave"
  defp abbreviate_station_name(full_name), do: full_name

  defp cause_description(%Alert{cause: :unknown}), do: ""
  defp cause_description(alert), do: "due to " <> Alert.cause_description(alert)

  @spec get_endpoints(list(Alert.informed_entity()), Route.id(), Stop.id()) ::
          {String.t(), String.t()} | nil
  defp get_endpoints(informed_entities, route_id, home_stop) do
    with {left_endpoint, right_endpoint} <- do_get_endpoints(informed_entities, route_id) do
      orient_endpoints({left_endpoint, right_endpoint}, informed_entities, route_id, home_stop)
    end
  end

  defp do_get_endpoints(ie, "Green") do
    Enum.find_value(@green_line_branches, fn branch ->
      do_get_endpoints(ie, branch)
    end)
  end

  defp do_get_endpoints(informed_entities, route_id) do
    case Subway.stop_sequence_containing_informed_entities(informed_entities, route_id) do
      nil ->
        nil

      stop_sequence ->
        {min_index, max_index} =
          informed_entities
          |> Enum.filter(&Subway.stop_on_route?(&1.stop, stop_sequence))
          |> Enum.map(&Subway.stop_index_for_informed_entity(&1, stop_sequence))
          |> Enum.min_max()

        {_, min_station_name} = Enum.at(stop_sequence, min_index)
        {_, max_station_name} = Enum.at(stop_sequence, max_index)

        {min_full_name, _min_abbreviated_name} = min_station_name
        {max_full_name, _max_abbreviated_name} = max_station_name

        {abbreviate_station_name(min_full_name), abbreviate_station_name(max_full_name)}
    end
  end

  # In certain cases, we want to describe an alert's endpoints in the opposite direction,
  # i.e. direction ID 1 instead of 0, so we need to flip the endpoints tuple before it gets formatted to string.
  #
  # Endpoints should be passed to this function in the order of direction ID 0.
  # For example, orient_endpoints({"place-wondl", "place-gover"}, ...) and not orient_endpoints({"place-gover", "place-wondl"}, ...)

  # All Blue Line alerts
  defp orient_endpoints({left_endpoint, right_endpoint}, _informed_entities, "Blue", _home_stop) do
    {right_endpoint, left_endpoint}
  end

  # All Green Line alerts *except* those where the alert's informed stops ++ the screen's home stop satisfy these conditions:
  #   - includes at least one GLX stop
  #   - does not include any stops west of Copley
  defp orient_endpoints({left_endpoint, right_endpoint}, informed_entities, route_id, home_stop)
       when route_id in ["Green" | @green_line_branches] do
    if glx_oriented_alert?(informed_entities, home_stop) do
      {left_endpoint, right_endpoint}
    else
      {right_endpoint, left_endpoint}
    end
  end

  # Otherwise, we don't need to flip the endpoints.
  defp orient_endpoints({left_endpoint, right_endpoint}, _ies, _route_id, _home_stop) do
    {left_endpoint, right_endpoint}
  end

  defp glx_oriented_alert?(informed_entities, home_stop) do
    parent_station_ies = Enum.filter(informed_entities, &InformedEntity.parent_station?/1)

    # It's ok if the home stop is duplicated in this list due to also being informed by the alert.
    relevant_parent_stations = [home_stop | Enum.map(parent_station_ies, & &1.stop)]

    includes_glx = Enum.any?(relevant_parent_stations, &Subway.glx_stop?/1)

    stops_west_of_copley = Subway.gl_stops_west_of_copley()
    includes_west_of_copley = Enum.any?(relevant_parent_stations, &(&1 in stops_west_of_copley))

    includes_glx and not includes_west_of_copley
  end

  @spec format_endpoint_string({String.t(), String.t()} | nil) :: String.t() | nil
  defp format_endpoint_string(nil), do: nil

  defp format_endpoint_string({station, station}) do
    "at #{station}"
  end

  defp format_endpoint_string({min_station, max_station}) do
    "between #{min_station} and #{max_station}"
  end

  def serialize(%__MODULE__{is_terminal_station: is_terminal_station} = t) do
    location = LocalizedAlert.location(t, is_terminal_station)

    case placement(t) do
      :dual_screen -> serialize_dual_screen(t)
      :single_screen -> serialize_single_screen(t, location)
      :flex_zone -> serialize_flex_zone(t, location)
    end
  end

  @spec serialize_dual_screen(t()) :: dual_screen_serialized_response()
  defp serialize_dual_screen(t) do
    case DisruptionDiagram.serialize(t) do
      {:ok, diagram} -> t |> dual_screen_fields() |> Map.put(:disruption_diagram, diagram)
      {:error, reason} -> t |> report_diagram_error(reason) |> dual_screen_fallback_fields()
    end
  end

  @spec serialize_single_screen(t(), LocalizedAlert.location()) ::
          single_screen_serialized_response()

  defp serialize_single_screen(%__MODULE__{alert: %Alert{effect: :delay}} = t, location),
    do: single_screen_fields(t, location)

  defp serialize_single_screen(%__MODULE__{partial_closure_platform_names: []} = t, location) do
    case DisruptionDiagram.serialize(t) do
      {:ok, diagram} ->
        t |> single_screen_fields(location) |> Map.put(:disruption_diagram, diagram)

      {:error, reason} ->
        t |> report_diagram_error(reason) |> single_screen_fallback_fields(location)
    end
  end

  # Use diagram-less presentation for partial station closures
  defp serialize_single_screen(t, location), do: single_screen_fields(t, location)

  @spec serialize_flex_zone(t(), LocalizedAlert.location()) :: flex_serialized_response()
  defp serialize_flex_zone(t, location), do: flex_zone_fields(t, location)

  defp report_diagram_error(%__MODULE__{} = t, reason) do
    Report.warning("disruption_diagram_error",
      alert_id: t.alert.id,
      home_stop: t.location_context.home_stop,
      reason: reason
    )

    t
  end

  def audio_sort_key(%__MODULE__{is_priority: true}), do: [1]

  def audio_sort_key(%__MODULE__{} = t) do
    case serialize(t) do
      %{urgent: true} -> [1]
      %{effect: effect} when effect in [:delay] -> [1, 1]
      _ -> [1, 2]
    end
  end

  def audio_view(%__MODULE__{} = t) do
    case placement(t) do
      :flex_zone -> ScreensWeb.V2.Audio.ReconstructedAlertView
      _full_screen -> ScreensWeb.V2.Audio.ReconstructedAlertSingleScreenView
    end
  end

  def priority(%__MODULE__{is_priority: true}), do: [1]
  def priority(_t), do: [3]

  def slot_names(%__MODULE__{screen: %Screen{app_params: %PreFare{template: template}}} = t) do
    case placement(t) do
      :dual_screen ->
        [:full_body_duo]

      :single_screen ->
        if template == :duo, do: [:paged_main_content_left], else: [:full_body_right]

      :flex_zone ->
        [:large]
    end
  end

  def widget_type(%__MODULE__{} = t) do
    case placement(t) do
      :dual_screen -> :reconstructed_takeover
      :single_screen -> :single_screen_alert
      :flex_zone -> :reconstructed_large_alert
    end
  end

  def alert_ids(%__MODULE__{} = t), do: [t.alert.id]

  @suppressed_alert_ids ~w[645336]

  def valid_candidate?(%__MODULE__{alert: %{id: alert_id}}) do
    alert_id not in @suppressed_alert_ids
  end

  defimpl Screens.V2.WidgetInstance do
    def priority(t), do: ReconstructedAlert.priority(t)
    def serialize(t), do: ReconstructedAlert.serialize(t)
    def slot_names(t), do: ReconstructedAlert.slot_names(t)
    def widget_type(t), do: ReconstructedAlert.widget_type(t)
    def valid_candidate?(t), do: ReconstructedAlert.valid_candidate?(t)
    def audio_serialize(t), do: ReconstructedAlert.serialize(t)
    def audio_sort_key(t), do: ReconstructedAlert.audio_sort_key(t)
    def audio_valid_candidate?(t), do: ReconstructedAlert.valid_candidate?(t)
    def audio_view(t), do: ReconstructedAlert.audio_view(t)
  end

  defimpl Screens.V2.AlertsWidget do
    def alert_ids(t), do: ReconstructedAlert.alert_ids(t)
  end
end
