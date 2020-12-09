defmodule Screens.DupScreenData do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.{Dup, State}
  alias Screens.Departures.Departure

  # Filters for the types of alerts we care about
  @alert_route_types ~w[light_rail subway]a
  @alert_effects MapSet.new(~w[delay shuttle suspension station_closure]a)

  def by_screen_id("dup-bus-headsigns", _is_screen) do
    current_time = DateTime.utc_now()

    bus_headsigns = [
      "Saugus Center via Kennedy Dr & Square One Mall",
      "Malden via Square One Mall & Kennedy Dr",
      "Washington St & Pleasant St Weymouth",
      "West Lynn Garage via Cliftondale",
      "Weymouth Landing via Quincy Ave",
      "Harbor Point via South Bay Center",
      "Saugus Center via Square One Mall",
      "Quincy Center via Holbrook Court",
      "Quincy Center via Des Moines Rd",
      "Quincy Center via North Quincy",
      "Woodland Rd via Gateway Center",
      "Wellington via Gateway Center",
      "West Lynn Garage via Maverick",
      "Kenmore via South Bay Center",
      "Malden via Square One Mall",
      "Central Square via Cliftondale",
      "Quincy Center via Billings Rd",
      "Fort Point via Des Moines Rd",
      "Quincy Center via Coddington",
      "Quincy Center via Quincy Ave",
      "Montello via Holbrook Court",
      "Germantown via Coddington",
      "Haymarket via Cliftondale",
      "Quincy Center via McGrath",
      "Quincy Center via Shaw St",
      "Middleborough / Lakeville",
      "Hingham Depot via Center",
      "Kenmore via Boston Latin",
      "Logan Airport Terminal C",
      "Logan Airport via Andrew",
      "Squantum via Billings Rd",
      "Sullivan (Limited Stops)",
      "Ruggles (Limited Stops)",
      "Downtown via Navy Yard",
      "Germantown via McGrath",
      "Haymarket via Maverick",
      "Sullivan via Navy Yard",
      "Haymarket via Kenmore",
      "Watertown via Kenmore",
      "Chestnut Hill Mall",
      "Government Center",
      "Holbrook/Randolph",
      "Jack Satter House",
      "Melrose Highlands",
      "Wickford Junction",
      "Weymouth Landing",
      "Needham Heights",
      "South Shore Plaza",
      "Arlington Center",
      "Cleveland Circle",
      "Brighton Center",
      "Crawford Square",
      "Boston College",
      "Central Square",
      "Clarendon Hill",
      "Forge Park/495",
      "Watertown Yard",
      "East Weymouth",
      "Fields Corner",
      "Hingham Depot",
      "Linden Square",
      "Logan Airport",
      "North Station",
      "Quincy Center",
      "Reading Depot",
      "South Station",
      "Forest Hills",
      "Heath Street",
      "Lebanon Loop",
      "North Quincy",
      "West Medford",
      "Avon Square",
      "Cary Square",
      "Houghs Neck",
      "Park Street",
      "Salem Depot",
      "Woodland Rd",
      "Oak Square",
      "Providence",
      "Wellington",
      "Wonderland",
      "Braintree",
      "Greenbush",
      "Haverhill",
      "Haymarket",
      "Oak Grove",
      "Reservoir",
      "Riverside",
      "Stoughton",
      "Worcester",
      "Assembly",
      "Back Bay",
      "Downtown",
      "Mattapan",
      "Montello",
      "Plymouth",
      "Redstone",
      "Squantum",
      "Sullivan",
      "Chelsea",
      "Reading",
      "Drydock",
      "Bowdoin",
      "Alewife",
      "Ashmont",
      "Kenmore",
      "Malden",
      "Davis"
    ]

    departures =
      Enum.map(bus_headsigns, fn d ->
        %{route: "0", route_id: "0", destination: d, time: current_time, id: d}
      end)

    %{
      force_reload: false,
      success: true,
      header: "Bus Headsign Test",
      sections: [%{departures: departures, pill: :bus}],
      current_time: Screens.Util.format_time(current_time)
    }
  end

  def by_screen_id(screen_id, rotation_index)

  def by_screen_id(screen_id, rotation_index) when rotation_index in ~w[0 1] do
    %Dup{primary: primary_departures} = State.app_params(screen_id)

    alerts = fetch_and_interpret_alerts(primary_departures)

    line_count = station_line_count(primary_departures)

    current_time = DateTime.utc_now()

    case response_type(alerts, line_count, rotation_index) do
      :departures ->
        fetch_departures_response(primary_departures, current_time)

      :partial_alert ->
        fetch_partial_alert_response(primary_departures, alerts, current_time)

      :fullscreen_alert ->
        fetch_fullscreen_alert_response(primary_departures, alerts, line_count)
    end
  end

  def by_screen_id(screen_id, "2") do
    %Dup{secondary: secondary_departures} = State.app_params(screen_id)

    current_time = DateTime.utc_now()
    fetch_departures_response(secondary_departures, current_time)
  end

  defp response_type([], _, _), do: :departures

  defp response_type(alerts, line_count, rotation_index) do
    if Enum.any?(alerts, & &1.effect == :station_closure) do
      :fullscreen_alert
    else
      response_type_helper(alerts, line_count, rotation_index)
    end
  end

  defp response_type_helper([alert], 1, rotation_index) do
    case {alert.region, rotation_index} do
      {:inside, _} -> :fullscreen_alert
      {:boundary, "0"} -> :partial_alert
      {:boundary, "1"} -> :fullscreen_alert
    end
  end

  defp response_type_helper([_alert], 2, rotation_index) do
    case rotation_index do
      "0" -> :partial_alert
      "1" -> :fullscreen_alert
    end
  end

  defp response_type_helper([_alert1, _alert2], 2, _rotation_index) do
    :fullscreen_alert
  end

  defp fetch_and_interpret_alerts(%Dup.Departures{sections: sections}) do
    Enum.flat_map(sections, &fetch_and_interpret_alert/1)
  end

  defp fetch_and_interpret_alert(%Dup.Section{stop_ids: stop_ids, route_ids: route_ids, pill: pill}) do
    case fetch_alert(stop_ids, route_ids) do
      nil -> []
      alert -> [interpret_alert(alert, stop_ids, pill)]
    end
  end

  defp fetch_alert(stop_ids, route_ids) do
    opts = [
      stop_ids: stop_ids,
      route_ids: route_ids,
      route_types: @alert_route_types
    ]

    opts
    |> Alert.fetch()
    |> Enum.filter(fn a ->
      Alert.happening_now?(a) and a.effect in @alert_effects
    end)
    |> choose_alert()
  end

  defp interpret_alert(alert, stop_ids, pill) do
    [
      %{adjacent_stops: adjacent_stops1, headsign: headsign1},
      %{adjacent_stops: adjacent_stops2, headsign: headsign2}
    ] = Enum.map(stop_ids, fn id ->
      :screens
      |> Application.get_env(:dup_constants)
      |> Map.get(id)
    end)

    informed_stop_ids = Enum.map(alert.informed_entities, & &1.stop)

    alert_region = Screens.AdjacentStops.alert_region(informed_stop_ids, adjacent_stops1, adjacent_stops2)

    {region, headsign} = case alert_region do
      :disruption_toward_1 -> {:boundary, headsign1}
      :disruption_toward_2 -> {:boundary, headsign2}
      :middle -> {:inside, nil}
    end

    %{
      cause: alert.cause,
      effect: alert.effect,
      region: region,
      headsign: headsign,
      pill: pill
    }
  end

  defp choose_alert([]), do: nil

  defp choose_alert([first_alert | _] = alerts) do
    # Prioritize shuttle alerts when one exists; otherwise just choose the first in the list.
    Enum.find(alerts, first_alert, &(&1.effect == :shuttle))
  end

  defp fetch_departures_response(
         %Dup.Departures{header: header, sections: sections},
         current_time
       ) do
    sections_data = fetch_sections_data(sections)

    case sections_data do
      {:ok, data} ->
        %{
          force_reload: false,
          success: true,
          header: header,
          sections: data,
          current_time: Screens.Util.format_time(current_time),
          type: :departures
        }

      :error ->
        %{force_reload: false, success: false}
    end
  end

  defp fetch_partial_alert_response(primary_departures, alerts, current_time) do
    departures_response = fetch_departures_response(primary_departures, current_time)

    case departures_response do
      %{force_reload: false, success: true, sections: sections} ->
        %{departures_response |
          sections: limit_three_departures(sections),
          alerts: render_partial_alerts(alerts)
        }

      _ ->
        departures_response
    end
  end

  defp fetch_fullscreen_alert_response(%Dup.Departures{header: header}, [alert], line_count) do
    %{
      type: :full_screen_alert,
      force_reload: false,
      success: true,
      header: header,
      pattern: pattern(alert.region, alert.effect, line_count),
      color: color(alert.pill, alert.effect, line_count, 1),
      issue: render_alert_issue(alert),
      remedy: render_alert_remedy(alert)
    }
  end

  defp fetch_fullscreen_alert_response(%Dup.Departures{header: header}, [alert, _alert], _) do
    %{
      type: :full_screen_alert,
      force_reload: false,
      success: true,
      header: header,
      pattern: :x,
      color: :yellow,
      issue: render_alert_issue(alert),
      remedy: render_alert_remedy(alert)
    }
  end

  defp render_alert_remedy(alert) do
    icon = render_alert_remedy_icon(alert.effect)
    line = [%{format: :bold, text: render_alert_remedy(alert.effect)}]

    %{icon: icon, free_text: line}
  end

  defp pattern(_, :delay, _), do: :hatched
  defp pattern(_, :shuttle, 1), do: :x
  defp pattern(_, :shuttle, 2), do: :chevron
  defp pattern(:inside, :suspension, 1), do: :x
  defp pattern(_, :suspension, _), do: :chevron
  defp pattern(_, :station_closure, _), do: :x

  defp color(_, _, 2, 2), do: :yellow
  defp color(pill, :station_closure, 1, _), do: line_color(pill)
  defp color(_, :station_closure, 2, _), do: :yellow
  defp color(pill, _, _, _), do: line_color(pill)

  defp line_color(:mattapan), do: :red
  defp line_color(pill), do: pill

  @alert_cause_mapping %{
    an_earlier_mechanical_problem: "due to an earlier mechanical problem",
    an_earlier_signal_problem: "due to an earlier signal problem",
    construction: "for construction",
    crossing_malfunction: "due to a crossing malfunction",
    demonstration: "due to a nearby demonstration",
    disabled_train: "due to a disabled train",
    electrical_work: "for electrical work",
    fire: "due to a fire",
    hazmat_condition: "due to hazardous conditions",
    heavy_ridership: "due to heavy ridership",
    high_winds: "due to high winds",
    holiday: "for the holiday",
    hurricane: "due to severe weather",
    maintenance: "for maintenance",
    mechanical_problem: "due to a mechanical problem",
    medical_emergency: "due to a medical emergency",
    parade: "for a parade",
    police_action: "due to police action",
    power_problem: "due to a power issue",
    severe_weather: "due to severe weather",
    signal_problem: "due to a signal problem",
    slippery_rail: "due to slippery rails",
    snow: "due to snow conditions",
    special_event: "for a special event",
    speed_restriction: "due to a speed restriction",
    switch_problem: "due to a switch problem",
    tie_replacement: "for maintenance",
    track_problem: "due to a track problem",
    track_work: "for track work",
    unruly_passenger: "due to an unruly passenger",
    weather: "due to weather conditions"
  }

  defp render_alert_cause(cause) do
    Map.get(@alert_cause_mapping, cause, "")
  end

  @pill_to_specifier %{
    red: "Red Line",
    orange: "Orange Line",
    green: "Green Line",
    blue: "Blue Line",
    mattapan: "Mattapan Line"
  }

  defp render_alert_issue(%{effect: :delay, cause: cause}) do
    %{icon: :warning, free_text: [%{format: :bold, text: "SERVICE DISRUPTION"}, render_alert_cause(cause)]}
  end

  defp render_alert_issue(%{region: :inside, cause: cause}) do
    %{icon: :x, free_text: [%{format: :bold, text: "STATION CLOSED"}, render_alert_cause(cause)]}
  end

  defp render_alert_issue(%{region: :boundary, pill: pill, headsign: headsign}) do
    %{icon: :warning, free_text: [%{format: :bold, text: "No #{@pill_to_specifier[pill]}"}, "service to #{headsign}"]}
  end

  @alert_remedy_text_mapping %{
    delay: "Expect delays",
    shuttle: "Use shuttle bus",
    suspension: "Seek alternate route",
    station_closure: "Seek alternate route"
  }

  defp render_alert_remedy(effect) do
    @alert_remedy_text_mapping[effect]
  end

  @alert_remedy_icon_mapping %{
    delay: nil,
    shuttle: :shuttle,
    suspension: nil,
    station_closure: nil
  }

  defp render_alert_remedy_icon(effect) do
    @alert_remedy_icon_mapping[effect]
  end

  defp limit_three_departures([[d1, d2], [d3, _d4]]), do: [[d1, d2], [d3]]
  defp limit_three_departures([[d1, d2, d3, _d4]]), do: [[d1, d2, d3]]
  defp limit_three_departures(sections), do: sections

  defp render_partial_alerts([alert]) do
    [
      %{
        affected: alert.pill,
        content: render_partial_alert_content(alert)
      }
    ]
  end

  defp render_partial_alert_content(alert) do
    {specifier, service_or_trains} = partial_alert_specifier(alert)

    %{
      icon: :warning,
      text: [%{format: :bold, text: "No #{specifier}"}, service_or_trains]
    }
  end

  defp partial_alert_specifier(%{headsign: nil, pill: pill}) do
    {@pill_to_specifier[pill], "service"}
  end

  defp partial_alert_specifier(%{headsign: headsign}) do
    {headsign, "trains"}
  end

  defp fetch_sections_data([_, _] = sections) do
    sections_data = Enum.map(sections, &fetch_section_data(&1, 2))

    if Enum.any?(sections_data, fn data -> data == :error end) do
      :error
    else
      {:ok, Enum.map(sections_data, fn {:ok, data} -> data end)}
    end
  end

  defp fetch_sections_data([section]) do
    case fetch_section_data(section, 4) do
      {:ok, data} -> {:ok, [data]}
      :error -> :error
    end
  end

  defp fetch_section_data(
         %Dup.Section{stop_ids: stop_ids, route_ids: route_ids, pill: pill},
         num_rows
       ) do
    query_params = %{stop_ids: stop_ids, route_ids: route_ids}
    include_schedules? = Enum.member?([:cr, :ferry], pill)

    case Departure.fetch(query_params, include_schedules?) do
      {:ok, departures} ->
        section_departures =
          departures
          |> Enum.map(&Map.from_struct/1)
          |> Enum.sort_by(& &1.time)
          |> Enum.take(num_rows)

        {:ok, %{departures: section_departures, pill: pill}}

      :error ->
        :error
    end
  end

  defp station_line_count(%Dup.Departures{sections: [section | _]}) do
    stop_id = hd(section.stop_ids)
    if stop_id in Application.get_env(:screens, :two_line_stops), do: 2, else: 1
  end
end
