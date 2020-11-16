defmodule Screens.DupScreenData do
  @moduledoc false

  alias Screens.Config.{Dup, State}
  alias Screens.Departures.Departure

  @headsign_replacements %{
    "Government Center" => "Government Ctr",
    "Charlestown Navy Yard" => "Charlestown"
  }

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
          |> Enum.map(&replace_long_headsigns/1)
          |> Enum.sort_by(& &1.time)
          |> Enum.take(num_rows)

        {:ok, %{departures: section_departures, pill: pill}}

      :error ->
        :error
    end
  end

  defp replace_long_headsigns(%{destination: destination} = departure) do
    new_destination =
      case Map.get(@headsign_replacements, destination) do
        nil -> destination
        replacement -> replacement
      end

    %{departure | destination: new_destination}
  end
end
