defmodule Screens.V2.WidgetInstance.ReconstructedAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.FreeTextLine
  alias Screens.LocationContext
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.Alert, as: AlertWidget
  alias Screens.V2.WidgetInstance.Common.BaseAlert
  alias Screens.V2.WidgetInstance.ReconstructedAlert
  alias Screens.V2.WidgetInstance.Serializer.RoutePill

  defstruct screen: nil,
            alert: nil,
            now: nil,
            location_context: nil,
            # stop_sequences: nil,
            # routes_at_stop: nil,
            informed_stations_string: nil,
            is_terminal_station: false

  @type stop_id :: String.t()

  @type route_id :: String.t()

  @type t :: %__MODULE__{
          screen: Screen.t(),
          alert: Alert.t(),
          now: DateTime.t(),
          location_context: LocationContext.t(),
          # stop_sequences: list(list(stop_id())),
          # routes_at_stop: list(%{route_id: route_id(), active?: boolean()}),
          informed_stations_string: String.t(),
          is_terminal_station: boolean()
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
  defp get_destination(t, location) do
    informed_entities = BaseAlert.informed_entities(t)

    {direction_id, route_id} =
      informed_entities
      |> Enum.map(fn %{direction_id: direction_id, route: route} -> {direction_id, route} end)
      |> Enum.uniq()
      |> hd()

    cond do
      # When the alert is non-directional but the station is at the boundary:
      # direction_id will be nil, but we still want to show the alert impacts one direction only
      is_nil(direction_id) and location == :boundary ->
        BaseAlert.get_headsign_from_informed_entities(t)

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

  defp get_route_pills(routes) do
    routes
    |> Enum.group_by(fn
      "Green" <> _ -> "Green"
      route -> route
    end)
    |> Enum.map(
      &RoutePill.serialize_route_for_reconstructed_alert(&1, %{large: length(routes) == 1})
    )
  end

  defp serialize_takeover_alert(
         %__MODULE__{
           alert: %Alert{effect: :suspension, cause: cause}
         } = t
       ) do
    informed_entities = BaseAlert.informed_entities(t)
    affected_routes = BaseAlert.informed_subway_routes(t)
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
      routes: get_route_pills(affected_routes),
      effect: :suspension,
      urgent: true
    }
  end

  defp serialize_takeover_alert(
         %__MODULE__{
           alert: %Alert{effect: :shuttle, cause: cause}
         } = t
       ) do
    informed_entities = BaseAlert.informed_entities(t)
    affected_routes = BaseAlert.informed_subway_routes(t)
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
      routes: get_route_pills(affected_routes),
      effect: :shuttle,
      urgent: true
    }
  end

  defp serialize_takeover_alert(
         %__MODULE__{alert: %Alert{effect: :station_closure, cause: cause}} = t
       ) do
    affected_routes = BaseAlert.informed_subway_routes(t)
    cause_text = cause |> Alert.get_cause_string() |> String.capitalize()

    %{
      issue: "Station Closed",
      remedy: "Seek alternate route",
      location: "",
      cause: cause_text,
      routes: get_route_pills(affected_routes),
      effect: :station_closure,
      urgent: true
    }
  end

  defp serialize_inside_flex_alert(
         %__MODULE__{
           alert: %Alert{
             effect: :suspension,
             cause: cause
           }
         } = t
       ) do
    affected_routes = BaseAlert.informed_subway_routes(t)
    cause_text = Alert.get_cause_string(cause)

    %{
      issue: "No trains",
      remedy: "Seek alternate route",
      location: "",
      cause: cause_text,
      routes: get_route_pills(affected_routes),
      effect: :suspension,
      urgent: true
    }
  end

  defp serialize_inside_flex_alert(%__MODULE__{alert: %Alert{effect: :shuttle, cause: cause}} = t) do
    affected_routes = BaseAlert.informed_subway_routes(t)
    cause_text = Alert.get_cause_string(cause)

    %{
      issue: "No trains",
      remedy: "Use shuttle bus",
      location: "",
      cause: cause_text,
      routes: get_route_pills(affected_routes),
      effect: :shuttle,
      urgent: true
    }
  end

  defp serialize_inside_flex_alert(
         %__MODULE__{
           alert: %Alert{effect: :station_closure, cause: cause}
         } = t
       ) do
    affected_routes = BaseAlert.informed_subway_routes(t)
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
      routes: get_route_pills(affected_routes),
      effect: :station_closure,
      urgent: true
    }
  end

  defp serialize_inside_flex_alert(
         %__MODULE__{
           alert: %Alert{effect: :delay, severity: severity, header: header}
         } = t
       )
       when severity > 3 and severity < 7 do
    affected_routes = BaseAlert.informed_subway_routes(t)

    %{
      issue: header,
      remedy: "",
      location: "",
      cause: "",
      routes: get_route_pills(affected_routes),
      effect: :delay,
      urgent: false
    }
  end

  defp serialize_inside_flex_alert(
         %__MODULE__{
           alert: %Alert{effect: :delay, cause: cause, severity: severity}
         } = t
       )
       when severity >= 7 do
    affected_routes = BaseAlert.informed_subway_routes(t)
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
      routes: get_route_pills(affected_routes),
      effect: :severe_delay,
      urgent: true
    }
  end

  defp serialize_inside_alert(%__MODULE__{} = t) do
    if AlertWidget.takeover_alert?(t) do
      serialize_takeover_alert(t)
    else
      serialize_inside_flex_alert(t)
    end
  end

  defp serialize_boundary_alert(
         %__MODULE__{
           alert: %Alert{effect: :suspension, cause: cause, header: header}
         } = t
       ) do
    affected_routes = BaseAlert.informed_subway_routes(t)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        remedy: "Seek alternate route",
        location: "",
        cause: "",
        routes: get_route_pills(affected_routes),
        effect: :suspension,
        urgent: true
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
        routes: get_route_pills(affected_routes),
        effect: :suspension,
        urgent: true
      }
    end
  end

  defp serialize_boundary_alert(
         %__MODULE__{
           alert: %Alert{effect: :shuttle, cause: cause, header: header}
         } = t
       ) do
    affected_routes = BaseAlert.informed_subway_routes(t)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        remedy: "Use shuttle bus",
        location: "",
        cause: "",
        routes: get_route_pills(affected_routes),
        effect: :shuttle,
        urgent: true
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
        routes: get_route_pills(affected_routes),
        effect: :shuttle,
        urgent: true
      }
    end
  end

  defp serialize_boundary_alert(%__MODULE__{alert: %Alert{effect: :station_closure}}), do: nil

  defp serialize_boundary_alert(
         %__MODULE__{
           alert: %Alert{effect: :delay, severity: severity, header: header}
         } = t
       )
       when severity > 3 and severity < 7 do
    affected_routes = BaseAlert.informed_subway_routes(t)

    %{
      issue: header,
      remedy: "",
      location: "",
      cause: "",
      routes: get_route_pills(affected_routes),
      effect: :delay,
      urgent: false
    }
  end

  defp serialize_boundary_alert(
         %__MODULE__{
           alert: %Alert{effect: :delay, cause: cause, severity: severity, header: header}
         } = t
       )
       when severity >= 7 do
    affected_routes = BaseAlert.informed_subway_routes(t)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        remedy: "",
        location: "",
        cause: "",
        routes: get_route_pills(affected_routes),
        effect: :severe_delay,
        urgent: true
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
        routes: get_route_pills(affected_routes),
        effect: :severe_delay,
        urgent: true
      }
    end
  end

  defp serialize_boundary_alert(%__MODULE__{alert: %Alert{effect: :delay}}), do: nil

  defp serialize_outside_alert(
         %__MODULE__{alert: %Alert{effect: :suspension, cause: cause, header: header}} = t
       ) do
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = BaseAlert.informed_subway_routes(t)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        remedy: "Seek alternate route",
        location: "",
        cause: "",
        routes: get_route_pills(affected_routes),
        effect: :suspension,
        urgent: false
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
        routes: get_route_pills(affected_routes),
        effect: :suspension,
        urgent: false
      }
    end
  end

  defp serialize_outside_alert(
         %__MODULE__{alert: %Alert{effect: :shuttle, cause: cause, header: header}} = t
       ) do
    informed_entities = BaseAlert.informed_entities(t)
  
    affected_routes = BaseAlert.informed_subway_routes(t)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        remedy: "Use shuttle bus",
        location: "",
        cause: "",
        routes: get_route_pills(affected_routes),
        effect: :suspension,
        urgent: false
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
        routes: get_route_pills(affected_routes),
        effect: :shuttle,
        urgent: false
      }
    end
  end

  defp serialize_outside_alert(
         %__MODULE__{
           alert: %Alert{effect: :station_closure, cause: cause},
           informed_stations_string: informed_stations_string
         } = t
       ) do
    affected_routes = BaseAlert.informed_subway_routes(t)

    cause_text = Alert.get_cause_string(cause)

    %{
      issue: "Trains will bypass #{informed_stations_string}",
      remedy: "Seek alternate route",
      location: "",
      cause: cause_text,
      routes: get_route_pills(affected_routes),
      effect: :station_closure,
      urgent: false
    }
  end

  defp serialize_outside_alert(%__MODULE__{alert: %Alert{effect: :delay, header: header}} = t) do
    affected_routes = BaseAlert.informed_subway_routes(t)

    %{
      issue: header,
      remedy: "",
      location: "",
      cause: "",
      routes: get_route_pills(affected_routes),
      effect: :delay,
      urgent: false
    }
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

  def serialize(%__MODULE__{is_terminal_station: is_terminal_station} = t) do
    case BaseAlert.location(t, is_terminal_station) do
      :inside ->
        t |> serialize_inside_alert() |> Map.put(:region, :inside)

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
    if AlertWidget.takeover_alert?(t), do: [1], else: [3]
  end

  def slot_names(%__MODULE__{} = t) do
    if AlertWidget.takeover_alert?(t), do: [:full_body], else: [:large]
  end

  def widget_type(%__MODULE__{} = t) do
    if AlertWidget.takeover_alert?(t),
      do: :reconstructed_takeover,
      else: :reconstructed_large_alert
  end

  def alert_ids(%__MODULE__{} = t), do: [t.alert.id]

  def temporarily_override_alert(%__MODULE__{} = t) do
    # Prevent Porter and Charles/MGH pre-fare screens from incorrectly communicating
    # a RL alert that affects both the Ashmont and Braintree branches.
    not (t.alert.id == "495152" and
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

  # defimpl Screens.V2.SingleAlertWidget do
  #   alias Screens.V2.WidgetInstance.ReconstructedAlert

  #   def alert(instance), do: instance.alert

  #   def screen(instance), do: instance.screen

  #   def home_stop_id(instance), do: instance.screen.app_params.reconstructed_alert_widget.stop_id

  #   def routes_at_stop(instance), do: instance.routes_at_stop

  #   def stop_sequences(instance), do: instance.stop_sequences

  #   def headsign_matchers(_instance) do
  #     Application.get_env(:screens, :prefare_alert_headsign_matchers)
  #   end
  # end

  defimpl Screens.V2.AlertsWidget do
    def alert_ids(t), do: ReconstructedAlert.alert_ids(t)
  end
end
