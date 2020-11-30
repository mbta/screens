defmodule Screens.DupScreenData do
  @moduledoc false

  alias Screens.Config.{Dup, State}
  alias Screens.Departures.Departure

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

  def by_screen_id(screen_id, _is_screen) do
    %Dup{primary: primary_departures} = State.app_params(screen_id)

    current_time = DateTime.utc_now()
    response_type = fetch_response_type()

    case response_type do
      :departures -> fetch_departures_response(primary_departures, current_time)
    end
  end

  defp fetch_response_type, do: :departures

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
          current_time: Screens.Util.format_time(current_time)
        }

      :error ->
        %{force_reload: false, success: false}
    end
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
end
