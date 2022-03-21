defmodule Screens.V2.WidgetInstance.ReconstructedAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Dup.Override.FreeTextLine
  alias Screens.Config.Screen
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.Alert, as: AlertWidget
  alias Screens.V2.WidgetInstance.Common.BaseAlert
  alias Screens.V2.WidgetInstance.ReconstructedAlert

  defstruct screen: nil,
            alert: nil,
            now: nil,
            stop_sequences: nil,
            routes_at_stop: nil

  @type stop_id :: String.t()

  @type route_id :: String.t()

  @type t :: %__MODULE__{
          screen: Screen.t(),
          alert: Alert.t(),
          now: DateTime.t(),
          stop_sequences: list(list(stop_id())),
          routes_at_stop: list(%{route_id: route_id(), active?: boolean()})
        }

  @route_directions %{
    "Blue" => ["Bowdoin", "Wonderland"],
    "Orange" => ["Forest Hills", "Oak Grove"],
    "Red" => ["Ashmont/Braintree", "Alewife"],
    "Green-B" => ["Boston College", "Government Center"],
    "Green-C" => ["Cleveland Circle", "Government Center"],
    "Green-D" => ["Riverside", "North Station"],
    "Green-E" => ["Heath Street", "North Station"]
  }

  defp get_affected_routes(informed_entities) do
    informed_entities |> Enum.map(fn %{route: route} -> route end) |> Enum.uniq()
  end

  # Using hd/1 because we know that only single line stations use this function.
  defp get_destination(%__MODULE__{} = t) do
    informed_entities = BaseAlert.informed_entities(t)

    {direction_id, route_id} =
      informed_entities
      |> Enum.map(fn %{direction_id: direction_id, route: route} -> {direction_id, route} end)
      |> Enum.uniq()
      |> hd()

    if is_nil(direction_id) do
      nil
    else
      @route_directions
      |> Map.get(route_id)
      |> Enum.at(direction_id)
    end
  end

  defp serialize_takeover_alert(
         %__MODULE__{
           alert: %Alert{effect: :suspension, cause: cause}
         } = t
       ) do
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)
    cause_text = cause |> get_cause_text() |> String.capitalize()

    location_text = get_endpoints(informed_entities, hd(affected_routes))

    issue_text =
      ["No"] ++
        (affected_routes
         |> Enum.map(fn route -> %{icon: route} end)
         |> Enum.to_list()) ++
        ["trains"]

    %{
      issue: %FreeTextLine{
        icon: nil,
        text: issue_text
      },
      location: location_text,
      cause: cause_text,
      routes: affected_routes,
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

    affected_routes = get_affected_routes(informed_entities)
    cause_text = cause |> get_cause_text() |> String.capitalize()

    location_text = get_endpoints(informed_entities, hd(affected_routes))

    issue_text =
      ["No"] ++
        (affected_routes
         |> Enum.map(fn route -> %{icon: route} end)
         |> Enum.to_list()) ++
        ["trains"]

    %{
      issue: %FreeTextLine{
        icon: nil,
        text: issue_text
      },
      location: location_text,
      cause: cause_text,
      routes: affected_routes,
      effect: :shuttle,
      urgent: true
    }
  end

  defp serialize_takeover_alert(
         %__MODULE__{alert: %Alert{effect: :station_closure, cause: cause}} = t
       ) do
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)
    cause_text = cause |> get_cause_text() |> String.capitalize()

    %{
      issue: "Station Closure",
      location: "",
      cause: cause_text,
      routes: affected_routes,
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
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)
    cause_text = get_cause_text(cause)

    %{
      issue: "No trains",
      location: "",
      cause: cause_text,
      routes: affected_routes,
      effect: :suspension,
      urgent: true
    }
  end

  defp serialize_inside_flex_alert(%__MODULE__{alert: %Alert{effect: :shuttle, cause: cause}} = t) do
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)
    cause_text = get_cause_text(cause)

    %{
      issue: "No trains",
      location: "",
      cause: cause_text,
      routes: affected_routes,
      effect: :shuttle,
      urgent: true
    }
  end

  defp serialize_inside_flex_alert(
         %__MODULE__{
           alert: %Alert{effect: :station_closure, cause: cause}
         } = t
       ) do
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)
    cause_text = get_cause_text(cause)

    line =
      case affected_routes do
        ["Green-" <> branch] -> "Green Line #{branch}"
        [affected_line] -> affected_line
      end

    %{
      issue: "#{line} platform closed",
      location: "",
      cause: cause_text,
      routes: affected_routes,
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
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)

    %{
      issue: header,
      location: "",
      cause: "",
      routes: affected_routes,
      effect: :moderate_delay,
      urgent: false
    }
  end

  defp serialize_inside_flex_alert(
         %__MODULE__{
           alert: %Alert{effect: :delay, cause: cause, severity: severity}
         } = t
       )
       when severity >= 7 do
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)
    cause_text = get_cause_text(cause)
    {delay_description, delay_minutes} = Alert.interpret_severity(severity)

    duration_text =
      case delay_description do
        :up_to -> "up to #{delay_minutes} minutes"
        :more_than -> "over #{delay_minutes} minutes"
      end

    %{
      issue: "Trains may be delayed #{duration_text}",
      location: "",
      cause: cause_text,
      routes: affected_routes,
      effect: :severe_delay,
      urgent: true
    }
  end

  defp serialize_inside_alert(%__MODULE__{} = t) do
    case AlertWidget.takeover_alert?(t) do
      true -> serialize_takeover_alert(t)
      _ -> serialize_inside_flex_alert(t)
    end
  end

  defp serialize_boundary_alert(
         %__MODULE__{
           alert: %Alert{effect: :suspension, cause: cause, header: header}
         } = t
       ) do
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        location: "",
        cause: "",
        routes: affected_routes,
        effect: :suspension,
        urgent: true
      }
    else
      destination = get_destination(t)
      cause_text = get_cause_text(cause)

      issue =
        if is_nil(destination) do
          "No trains"
        else
          "No #{destination} trains"
        end

      %{
        issue: issue,
        location: "",
        cause: cause_text,
        routes: affected_routes,
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
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        location: "",
        cause: "",
        routes: affected_routes,
        effect: :shuttle,
        urgent: true
      }
    else
      destination = get_destination(t)
      cause_text = get_cause_text(cause)

      issue =
        if is_nil(destination) do
          "No trains"
        else
          "No #{destination} trains"
        end

      %{
        issue: issue,
        location: "",
        cause: cause_text,
        routes: affected_routes,
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
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)

    %{
      issue: header,
      location: "",
      cause: "",
      routes: affected_routes,
      effect: :moderate_delay,
      urgent: false
    }
  end

  defp serialize_boundary_alert(
         %__MODULE__{
           alert: %Alert{effect: :delay, cause: cause, severity: severity, header: header}
         } = t
       )
       when severity >= 7 do
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        location: "",
        cause: "",
        routes: affected_routes,
        effect: :severe_delay,
        urgent: true
      }
    else
      cause_text = get_cause_text(cause)
      {delay_description, delay_minutes} = Alert.interpret_severity(severity)
      destination = get_destination(t)

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
        location: "",
        cause: cause_text,
        routes: affected_routes,
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

    affected_routes = get_affected_routes(informed_entities)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        location: "",
        cause: "",
        routes: affected_routes,
        effect: :suspension,
        urgent: false
      }
    else
      destination = get_destination(t)
      cause_text = get_cause_text(cause)
      location_text = get_endpoints(informed_entities, hd(affected_routes))

      issue =
        if is_nil(destination) do
          "No trains"
        else
          "No #{destination} trains"
        end

      %{
        issue: issue,
        location: location_text,
        cause: cause_text,
        routes: affected_routes,
        effect: :suspension,
        urgent: false
      }
    end
  end

  defp serialize_outside_alert(
         %__MODULE__{alert: %Alert{effect: :shuttle, cause: cause, header: header}} = t
       ) do
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)

    if length(affected_routes) > 1 do
      %{
        issue: header,
        location: "",
        cause: "",
        routes: affected_routes,
        effect: :suspension,
        urgent: false
      }
    else
      destination = get_destination(t)
      cause_text = get_cause_text(cause)
      location_text = get_endpoints(informed_entities, List.first(affected_routes))

      issue =
        if is_nil(destination) do
          "No trains"
        else
          "No #{destination} trains"
        end

      %{
        issue: issue,
        location: location_text,
        cause: cause_text,
        routes: affected_routes,
        effect: :shuttle,
        urgent: false
      }
    end
  end

  defp serialize_outside_alert(
         %__MODULE__{alert: %Alert{effect: :station_closure, cause: cause}} = t
       ) do
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)
    cause_text = get_cause_text(cause)

    %{
      issue: "Trains will bypass <Station>",
      location: "",
      cause: cause_text,
      routes: affected_routes,
      effect: :station_closure,
      urgent: false
    }
  end

  defp serialize_outside_alert(%__MODULE__{alert: %Alert{effect: :delay, header: header}} = t) do
    affected_routes = t |> BaseAlert.informed_entities() |> get_affected_routes()

    %{
      issue: header,
      location: "",
      cause: "",
      routes: affected_routes,
      effect: :delay,
      urgent: false
    }
  end

  defp get_cause_text(cause) do
    if cause != :unknown do
      "Due to #{cause}"
    else
      ""
    end
  end

  def get_endpoints(informed_entities, route_id) do
    case Stop.get_stop_sequence(informed_entities, route_id) do
      nil ->
        nil

      stop_sequence ->
        {min_index, max_index} =
          informed_entities
          |> Enum.filter(&Stop.stop_on_route?(&1, stop_sequence))
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

  def serialize(%__MODULE__{} = t) do
    case BaseAlert.location(t) do
      :inside ->
        serialize_inside_alert(t)

      location when location in [:boundary_upstream, :boundary_downstream] ->
        serialize_boundary_alert(t)

      location when location in [:downstream, :upstream] ->
        serialize_outside_alert(t)
    end
  end

  def priority(%__MODULE__{} = t) do
    if AlertWidget.takeover_alert?(t), do: [1], else: [3]
  end

  def slot_names(%__MODULE__{} = t) do
    if AlertWidget.takeover_alert?(t), do: [:full_body], else: [:large]
  end

  defimpl Screens.V2.WidgetInstance do
    def priority(t), do: ReconstructedAlert.priority(t)
    def serialize(t), do: ReconstructedAlert.serialize(t)
    def slot_names(t), do: ReconstructedAlert.slot_names(t)
    def widget_type(_instance), do: :reconstructed_alert
    def valid_candidate?(_instance), do: true
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: 0
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.ReconstructedAlertView
  end
end
