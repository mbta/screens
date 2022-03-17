defmodule Screens.V2.WidgetInstance.ReconstructedAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.Header.CurrentStopId
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

  @alert_headsign_matchers %{
    # Kenmore
    "place-kencl" => [
      {"70149", ~w[70153 70211 70187], "Boston College"},
      {"70211", ~w[70153 70149 70187], "Cleveland Circle"},
      {"70187", ~w[70153 70149 70211], "Riverside"},
      {~w[70149 70211], ~w[70153 70187], "BC/Clev. Circ."},
      {~w[70149 70187], ~w[70153 70211], "BC/Riverside"},
      {~w[70211 70187], ~w[70153 70149], "Clev. Circ./Riverside"},
      {~w[70149 70211 70187], "70153", {:adj, "westbound"}},
      {"70152", ~w[70148 70212 70186], "Park Street"}
    ],
    # Prudential
    "place-prmnl" => [
      {"70154", "70242", "Park Street"},
      {"70241", "70155", "Heath Street"}
    ],
    # Haymarket
    "place-haecl" => [
      # GL
      {"70205", "70201", "Northbound"},
      {"70202", "70206", "Copley & West"},
      # OL
      {"70027", "70023", "Oak Grove"},
      {"70022", "70026", "Forest Hills"}
    ],
    # Back Bay
    "place-bbsta" => [
      {"70017", "70013", "Oak Grove"},
      {"70012", "70016", "Forest Hills"}
    ],
    # Tufts
    "place-tumnl" => [
      {"70019", "70015", "Oak Grove"},
      {"70014", "70018", "Forest Hills"}
    ],
    # Sullivan
    "place-sull" => [
      {"70279", "70029", "Oak Grove"},
      {"70028", "70278", "Forest Hills"}
    ],
    # Malden Center
    "place-mlmnl" => [
      {"70036", "70033", "Oak Grove"},
      {"70032", "70036", "Forest Hills"}
    ],
    # Broadway
    "place-brdwy" => [
      {"70080", "70084", "Alewife"},
      {"70083", "70079", "Ashmont/Braintree"}
    ],
    # Aquarium
    "place-aqucl" => [
      {"70046", "70042", "Wonderland"},
      {"70041", "70045", "Bowdoin"}
    ],
    # Airport
    "place-aport" => [
      {"70050", "70046", "Wonderland"},
      {"70045", "70049", "Bowdoin"}
    ],
    # Quincy Center
    "place-qnctr" => [
      {"70100", "70104", "Alewife"},
      {"70103", "70099", "Braintree"}
    ]
  }

  defp parent_stop_id(%__MODULE__{
         screen: %Screen{app_params: %_{header: %CurrentStopId{stop_id: parent_stop_id}}}
       }) do
    parent_stop_id
  end

  defp get_affected_routes(informed_entities) do
    informed_entities |> Enum.map(fn %{route: route} -> route end) |> Enum.uniq()
  end

  defp get_destination(parent_stop_id) do
    @alert_headsign_matchers
    |> Map.get(parent_stop_id)
    |> Enum.find_value({:inside, nil}, fn {_informed, _not_informed, headsign} ->
      headsign
    end)
  end

  defp serialize_takeover_alert(
         %__MODULE__{
           alert: %Alert{effect: :suspension, cause: cause}
         } = t
       ) do
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)
    cause_text = cause |> get_cause_text() |> String.capitalize()

    location_text =
      get_endpoints(informed_entities, List.first(affected_routes)) |> String.capitalize()

    %{
      issue: "No <SMPILL> trains",
      location: location_text,
      cause: cause_text,
      remedy: "Seek alternate route",
      routes: affected_routes,
      effect: :suspension
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

    location_text =
      get_endpoints(informed_entities, List.first(affected_routes)) |> String.capitalize()

    %{
      issue: "No <SMPILL> trains",
      location: location_text,
      cause: cause_text,
      remedy: "Use shuttle bus",
      routes: affected_routes,
      effect: :shuttle
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
      remedy: "Seek alternate route",
      routes: affected_routes,
      effect: :station_closure
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
    cause_text = cause |> get_cause_text()

    %{
      issue: "No trains",
      location: "",
      cause: cause_text,
      remedy: "Seek alternate route",
      routes: affected_routes,
      effect: :suspension
    }
  end

  defp serialize_inside_flex_alert(%__MODULE__{alert: %Alert{effect: :shuttle, cause: cause}} = t) do
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)
    cause_text = cause |> get_cause_text()

    %{
      issue: "No trains",
      location: "",
      cause: cause_text,
      remedy: "Use shuttle bus",
      routes: affected_routes,
      effect: :shuttle
    }
  end

  defp serialize_inside_flex_alert(
         %__MODULE__{
           alert: %Alert{effect: :station_closure, cause: cause}
         } = t
       ) do
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)
    cause_text = cause |> get_cause_text()

    %{
      issue: "<LINE> platform closed",
      location: "",
      cause: cause_text,
      remedy: "Seek alternate route",
      routes: affected_routes,
      effect: :station_closure
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
      remedy: "",
      routes: affected_routes,
      effect: :moderate_delay
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
    cause_text = cause |> get_cause_text()
    {delay_description, delay_minutes} = Alert.interpret_severity(severity)

    %{
      issue: "Trains may be delayed #{delay_description} #{delay_minutes}",
      location: "",
      cause: cause_text,
      remedy: "",
      routes: affected_routes,
      effect: :severe_delay
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
           alert: %Alert{effect: :suspension, cause: cause}
         } = t
       ) do
    informed_entities = BaseAlert.informed_entities(t)
    parent_stop_id = parent_stop_id(t)

    affected_routes = get_affected_routes(informed_entities)
    cause_text = cause |> get_cause_text()
    destination = parent_stop_id |> get_destination()

    %{
      issue: "No #{destination} trains",
      location: "",
      cause: cause_text,
      remedy: "Seek alternate route",
      routes: affected_routes,
      effect: :suspension
    }
  end

  defp serialize_boundary_alert(%__MODULE__{alert: %Alert{effect: :shuttle, cause: cause}} = t) do
    informed_entities = BaseAlert.informed_entities(t)
    parent_stop_id = parent_stop_id(t)

    affected_routes = get_affected_routes(informed_entities)
    cause_text = cause |> get_cause_text()
    destination = parent_stop_id |> get_destination()

    %{
      issue: "No #{destination} trains",
      location: "",
      cause: cause_text,
      remedy: "Use shuttle bus",
      routes: affected_routes,
      effect: :shuttle
    }
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
      remedy: "",
      routes: affected_routes,
      effect: :moderate_delay
    }
  end

  defp serialize_boundary_alert(
         %__MODULE__{
           alert: %Alert{effect: :delay, cause: cause, severity: severity}
         } = t
       )
       when severity >= 7 do
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)
    cause_text = cause |> get_cause_text()
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
      remedy: "",
      routes: affected_routes,
      effect: :severe_delay
    }
  end

  defp serialize_boundary_alert(%__MODULE__{alert: %Alert{effect: :delay}}), do: nil

  defp serialize_outside_alert(%__MODULE__{alert: %Alert{effect: :suspension, cause: cause}} = t) do
    informed_entities = BaseAlert.informed_entities(t)
    parent_stop_id = parent_stop_id(t)

    affected_routes = get_affected_routes(informed_entities)
    location_text = get_endpoints(informed_entities, List.first(affected_routes))

    cause_text = cause |> get_cause_text()
    destination = parent_stop_id |> get_destination()

    %{
      issue: "No #{destination} trains",
      location: location_text,
      cause: cause_text,
      remedy: "Seek alternate route",
      routes: affected_routes,
      effect: :suspension
    }
  end

  defp serialize_outside_alert(%__MODULE__{alert: %Alert{effect: :shuttle, cause: cause}} = t) do
    informed_entities = BaseAlert.informed_entities(t)
    parent_stop_id = parent_stop_id(t)

    affected_routes = get_affected_routes(informed_entities)
    location_text = get_endpoints(informed_entities, List.first(affected_routes))

    cause_text = cause |> get_cause_text()
    destination = parent_stop_id |> get_destination()

    %{
      issue: "No #{destination} trains",
      location: location_text,
      cause: cause_text,
      remedy: "Use shuttle bus",
      routes: affected_routes,
      effect: :shuttle
    }
  end

  defp serialize_outside_alert(
         %__MODULE__{alert: %Alert{effect: :station_closure, cause: cause}} = t
       ) do
    informed_entities = BaseAlert.informed_entities(t)

    affected_routes = get_affected_routes(informed_entities)
    cause_text = cause |> get_cause_text()

    %{
      issue: "Trains will bypass <Station>",
      location: "",
      cause: cause_text,
      remedy: "Seek alternate route",
      routes: affected_routes,
      effect: :station_closure
    }
  end

  defp serialize_outside_alert(%__MODULE__{alert: %Alert{effect: :delay, header: header}} = t) do
    affected_routes = t |> BaseAlert.informed_entities() |> get_affected_routes()

    %{
      issue: header,
      location: "",
      cause: "",
      remedy: "",
      routes: affected_routes,
      effect: :delay
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

        "between #{min_full_name} and #{max_full_name}"
    end
  end

  def serialize(%__MODULE__{} = t) do
    case BaseAlert.location(t) do
      :inside ->
        serialize_inside_alert(t) |> IO.inspect(label: "inside")

      location when location in [:boundary_upstream, :boundary_downstream] ->
        serialize_boundary_alert(t) |> IO.inspect(label: "boundary")

      location when location in [:downstream, :upstream] ->
        serialize_outside_alert(t) |> IO.inspect(label: "outside")
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
