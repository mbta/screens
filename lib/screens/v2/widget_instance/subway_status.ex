defmodule Screens.V2.WidgetInstance.SubwayStatus do
  @moduledoc false

  require Logger

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.SubwayStatus

  defstruct screen: nil,
            subway_alerts: nil

  @type t :: %__MODULE__{
          screen: Screen.t(),
          subway_alerts: list(Alert.t())
        }

  @route_directions %{
    "Blue" => ["Westbound", "Eastbound"],
    "Orange" => ["Southbound", "Northbound"],
    "Red" => ["Southbound", "Northbound"],
    "Green-B" => ["Westbound", "Eastbound"],
    "Green-C" => ["Westbound", "Eastbound"],
    "Green-D" => ["Westbound", "Eastbound"],
    "Green-E" => ["Westbound", "Eastbound"],
    "Green" => ["Westbound", "Eastbound"]
  }

  @green_line_branches ["Green-B", "Green-C", "Green-D", "Green-E"]

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2, 1]

    def serialize(%SubwayStatus{subway_alerts: alerts}) do
      grouped_alerts = SubwayStatus.get_relevant_alerts_by_route(alerts)

      %{
        blue: SubwayStatus.serialize_route(grouped_alerts, "Blue"),
        orange: SubwayStatus.serialize_route(grouped_alerts, "Orange"),
        red: SubwayStatus.serialize_route(grouped_alerts, "Red"),
        green: SubwayStatus.serialize_green_line(grouped_alerts)
      }
    end

    def slot_names(_instance), do: [:large]

    def widget_type(_instance), do: :subway_status

    def valid_candidate?(_instance), do: true

    def audio_serialize(_instance), do: %{}

    def audio_sort_key(_instance), do: [0]

    def audio_valid_candidate?(_instance), do: false

    def audio_view(_instance), do: ScreensWeb.V2.Audio.SubwayStatusView
  end

  def get_relevant_alerts_by_route(alerts) do
    alerts
    |> Stream.filter(&Alert.happening_now?/1)
    |> Stream.filter(&relevant_effect?/1)
    |> Stream.flat_map(fn alert ->
      Enum.map(alert_routes(alert), fn route -> {alert, route} end)
    end)
    |> Enum.group_by(fn {_alert, route} -> route end, fn {alert, _route} -> alert end)
  end

  defp relevant_effect?(%Alert{effect: :suspension}), do: true
  defp relevant_effect?(%Alert{effect: :shuttle}), do: true
  defp relevant_effect?(%Alert{effect: :delay}), do: true
  defp relevant_effect?(%Alert{effect: :station_closure}), do: true
  defp relevant_effect?(_), do: false

  defp alert_routes(%Alert{informed_entities: entities}) do
    entities
    |> Enum.map(fn e -> Map.get(e, :route) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  def serialize_route(grouped_alerts, route_id) do
    alerts = Map.get(grouped_alerts, route_id)

    data =
      case alerts do
        nil ->
          %{status: "Normal Service"}

        [] ->
          %{status: "Normal Service"}

        [alert] ->
          serialize_alert(alert, route_id)

        alerts ->
          _ =
            Logger.info(
              "[subway_status_multiple_alerts] route=#{route_id} count=#{length(alerts)}"
            )

          %{
            status: "#{length(alerts)} alerts",
            location: %{full: "mbta.com/alerts/subway", abbrev: "mbta.com/alerts/subway"}
          }
      end

    Map.merge(%{route: serialize_route_pill(route_id)}, data)
  end

  defp serialize_route_pill(route_id) do
    case route_id do
      "Blue" -> %{type: :text, color: :blue, text: "BL"}
      "Orange" -> %{type: :text, color: :orange, text: "OL"}
      "Red" -> %{type: :text, color: :red, text: "RL"}
      _ -> %{type: :text, color: :green, text: "GL"}
    end
  end

  defp ie_is_whole_route?(%{route: route_id, direction_id: nil, stop: nil})
       when not is_nil(route_id),
       do: true

  defp ie_is_whole_route?(_), do: false

  defp ie_is_whole_direction?(%{route: route_id, direction_id: direction_id, stop: nil})
       when not is_nil(route_id) and not is_nil(direction_id),
       do: true

  defp ie_is_whole_direction?(_), do: false

  defp alert_is_whole_route?(informed_entities) do
    Enum.any?(informed_entities, &ie_is_whole_route?/1)
  end

  defp alert_is_whole_direction?(informed_entities) do
    Enum.any?(informed_entities, &ie_is_whole_direction?/1)
  end

  defp get_direction(informed_entities, route_id) do
    [%{direction_id: direction_id} | _] =
      Enum.filter(informed_entities, &ie_is_whole_direction?/1)

    direction =
      @route_directions
      |> Map.get(route_id)
      |> Enum.at(direction_id)

    %{full: direction, abbrev: direction}
  end

  defp get_endpoints(informed_entities, route_id) do
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

        {min_full_name, min_abbreviated_name} = min_station_name
        {max_full_name, max_abbreviated_name} = max_station_name

        %{
          full: "#{min_full_name} to #{max_full_name}",
          abbrev: "#{min_abbreviated_name} to #{max_abbreviated_name}"
        }
    end
  end

  defp get_location(informed_entities, route_id) do
    cond do
      alert_is_whole_route?(informed_entities) ->
        nil

      alert_is_whole_direction?(informed_entities) ->
        get_direction(informed_entities, route_id)

      true ->
        get_endpoints(informed_entities, route_id)
    end
  end

  defp serialize_alert(%Alert{effect: :shuttle, informed_entities: informed_entities}, route_id) do
    %{status: "Shuttle Buses", location: get_location(informed_entities, route_id)}
  end

  defp serialize_alert(
         %Alert{effect: :suspension, informed_entities: informed_entities},
         route_id
       ) do
    location = get_location(informed_entities, route_id)
    status = if is_nil(location), do: "SERVICE SUSPENDED", else: "Suspension"
    %{status: status, location: location}
  end

  defp serialize_alert(
         %Alert{effect: :station_closure, informed_entities: informed_entities},
         route_id
       ) do
    # Get closed station names from informed entities
    stop_id_to_name = Stop.stop_id_to_name(route_id)

    stop_names =
      informed_entities
      |> Enum.flat_map(fn
        %{stop: stop_id} ->
          case Map.get(stop_id_to_name, stop_id) do
            nil -> []
            name -> [name]
          end

        _ ->
          []
      end)
      |> Enum.uniq()

    location =
      case stop_names do
        [] ->
          _ = Logger.info("[subway_status_empty_bypassing]")
          nil

        [stop_name] ->
          {full_name, abbreviated_name} = stop_name
          %{full: full_name, abbrev: abbreviated_name}

        [stop_name1, stop_name2] ->
          {full_name1, abbreviated_name1} = stop_name1
          {full_name2, abbreviated_name2} = stop_name2

          %{
            full: "#{full_name1} and #{full_name2}",
            abbrev: "#{abbreviated_name1} and #{abbreviated_name2}"
          }

        stop_names ->
          %{full: "#{length(stop_names)} stops", abbrev: "#{length(stop_names)} stops"}
      end

    %{status: "Bypassing", location: location}
  end

  defp serialize_alert(
         %Alert{
           effect: :delay,
           severity: severity,
           informed_entities: informed_entities
         },
         route_id
       ) do
    {delay_description, delay_minutes} = Alert.interpret_severity(severity)

    duration_text =
      case delay_description do
        :up_to -> "up to #{delay_minutes} minutes"
        :more_than -> "over #{delay_minutes} minutes"
      end

    %{status: "Delays #{duration_text}", location: get_location(informed_entities, route_id)}
  end

  def get_green_line_branch_status(%Alert{effect: :suspension}), do: "Suspension"
  def get_green_line_branch_status(%Alert{effect: :shuttle}), do: "Shuttle Buses"
  def get_green_line_branch_status(%Alert{effect: :delay}), do: "Delays"

  def get_green_line_branch_status(%Alert{
        effect: :station_closure,
        informed_entities: informed_entities
      }) do
    stations = get_stations(informed_entities)
    station_count = length(stations)

    _ =
      if station_count == 0 do
        Logger.info("[subway_status_station_count_zero]")
      end

    "Bypassing #{station_count} #{if station_count == 1, do: "stop", else: "stops"}"
  end

  def get_stations(informed_entities) do
    informed_entities
    |> Enum.map(fn %{stop: stop_id} -> stop_id end)
    |> Enum.filter(&String.starts_with?(&1, "place-"))
  end

  def get_green_line_branch_statuses(alerts) do
    Enum.map(alerts, &get_green_line_branch_status/1)
  end

  def group_green_line_branch_statuses(statuses_by_route) do
    statuses_by_route
    |> Enum.flat_map(fn {route, statuses} -> Enum.map(statuses, fn s -> {route, s} end) end)
    |> Enum.group_by(fn {_route, status} -> status end, fn {route, _status} -> route end)
    |> Enum.map(fn {status, routes} -> [Enum.uniq(routes), status] end)
    |> Enum.sort_by(fn [[first_route | _other_routes], _status] -> first_route end)
  end

  defp alert_affects_gl_trunk_or_whole_line?(%Alert{informed_entities: informed_entities}) do
    gl_trunk_stops = Stop.gl_trunk_stops()

    alert_trunk_stops =
      informed_entities
      |> Enum.map(fn e -> Map.get(e, :stop) end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.into(MapSet.new())
      |> MapSet.intersection(gl_trunk_stops)

    alert_whole_line_stops =
      informed_entities
      |> Enum.map(fn e -> Map.get(e, :route) end)
      |> Enum.filter(fn
        "Green-" <> _ -> true
        _ -> false
      end)
      |> Enum.uniq()
      |> Enum.sort()

    MapSet.size(alert_trunk_stops) > 0 or
      alert_whole_line_stops == @green_line_branches
  end

  defp is_multi_route?(alert) do
    length(alert_routes(alert)) > 1
  end

  def serialize_green_line(grouped_alerts) do
    green_line_alerts =
      @green_line_branches
      |> Enum.flat_map(fn route -> Map.get(grouped_alerts, route, []) end)
      |> Enum.uniq()

    multi_route_alerts = Enum.filter(green_line_alerts, &is_multi_route?/1)
    single_route_alerts = Enum.reject(green_line_alerts, &is_multi_route?/1)
    trunk_alerts = Enum.filter(multi_route_alerts, &alert_affects_gl_trunk_or_whole_line?/1)
    alert_count = length(green_line_alerts)

    statuses =
      single_route_alerts
      |> Enum.group_by(fn alert -> Enum.at(alert_routes(alert), 0) end)
      |> Enum.map(fn {route, alerts} -> {route, get_green_line_branch_statuses(alerts)} end)
      |> group_green_line_branch_statuses()

    case trunk_alerts do
      [] ->
        # If there are no alerts for the GL trunk, serialize any alerts on the branches
        serialize_green_line_branch_alerts(statuses, single_route_alerts, alert_count)

      [trunk_alert] ->
        # If there is a single alert on the GL trunk, combine it with any alerts on the branches
        serialize_green_line_trunk_alert(trunk_alert, statuses, alert_count)

      _ ->
        # If there are multiple alerts on the GL trunk, log it and serialize the count
        _ = Logger.info("[subway_status_multiple_alerts] route=Green-Trunk count=#{alert_count}")

        %{
          type: :single,
          route: serialize_route_pill("Green"),
          status: "#{alert_count} alerts",
          location: %{full: "mbta.com/alerts/subway", abbrev: "mbta.com/alerts/subway"}
        }
    end
  end

  defp serialize_green_line_trunk_alert(trunk_alert, statuses, alert_count) do
    case statuses do
      [] ->
        # One GL trunk alert and no branch alerts
        Map.merge(
          %{type: :single, route: serialize_route_pill("Green")},
          serialize_alert(trunk_alert, "Green")
        )

      [status] ->
        # One GL trunk alert and one GL branch alert
        trunk_status = get_green_line_branch_status(trunk_alert)
        %{type: :multiple, statuses: [[nil, trunk_status], status]}

      _ ->
        # One GL trunk alert and 2+ GL branch alerts
        _ = Logger.info("[subway_status_multiple_alerts] route=Green-Trunk count=#{alert_count}")

        %{
          type: :single,
          route: serialize_route_pill("Green"),
          status: "#{alert_count} alerts",
          location: %{full: "mbta.com/alerts/subway", abbrev: "mbta.com/alerts/subway"}
        }
    end
  end

  defp serialize_green_line_branch_alerts(statuses, single_route_alerts, alert_count) do
    case {single_route_alerts, statuses} do
      # One GL branch alert
      {[alert], _} ->
        [route] = alert_routes(alert)

        Map.merge(
          %{type: :single, route: serialize_route_pill("Green"), branch: route},
          serialize_alert(alert, route)
        )

      # No GL alerts at all
      {_, []} ->
        %{type: :single, route: serialize_route_pill("Green"), status: "Normal Service"}

      # One group of GL branch alerts
      {_, [_] = statuses} ->
        %{type: :multiple, statuses: statuses}

      # Two groups of GL branch alerts
      {_, [_, _] = statuses} ->
        %{type: :multiple, statuses: statuses}

      # 3+ groups of GL branch alerts
      _ ->
        _ =
          Logger.info(
            "[subway_status_multiple_alerts] route=#{"Green-Branch"} count=#{alert_count}"
          )

        %{
          type: :single,
          route: serialize_route_pill("Green"),
          status: "#{alert_count} alerts",
          location: %{full: "mbta.com/alerts/subway", abbrev: "mbta.com/alerts/subway"}
        }
    end
  end
end
