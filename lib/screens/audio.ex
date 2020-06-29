defmodule Screens.Audio do
  @moduledoc false

  alias Screens.Util

  @lexicon_names ["mbtalexicon"]

  @type time_representation ::
          %{type: :text, value: String.t()}
          | %{type: :minutes, value: integer}
          | %{type: :timestamp, value: String.t()}

  @type departure_group_key :: {String.t(), String.t(), String.t()}

  @type departure_group :: {departure_group_key(), [map()]}

  def synthesize(ssml_string) do
    result =
      ssml_string
      |> ExAws.Polly.synthesize_speech(lexicon_names: @lexicon_names, text_type: "ssml")
      |> ExAws.request()

    case result do
      {:ok, %{body: audio_data}} -> {:ok, audio_data}
      _ -> :error
    end
  end

  def from_api_data(%{
        section_headers: section_headers,
        station_name: station_name,
        sections: sections,
        current_time: current_time
      }) do
    include_wayfinding = not is_nil(section_headers)

    %{
      station_name: station_name,
      departures_by_pill: group_departures_by_pill(sections, include_wayfinding, current_time)
    }
  end

  @spec group_departures_by_pill(list(map()), boolean(), String.t()) ::
          keyword([departure_group()])
  defp group_departures_by_pill(sections, include_wayfinding, current_time) do
    sections
    |> Enum.map(&move_data_to_departures(&1, include_wayfinding, current_time))
    |> Util.group_by_with_order(& &1.pill)
    |> Enum.map(fn {pill, sections} -> {pill, merge_section_departures(sections)} end)
  end

  @spec merge_section_departures([map()]) :: [departure_group()]
  defp merge_section_departures(sections) do
    sections
    |> Enum.flat_map(& &1.departures)
    |> Enum.sort_by(& &1.time)
    |> Util.group_by_with_order(&{&1.route, &1.route_id, &1.destination})
    |> Enum.map(fn {key, departures} ->
      {key,
       %{
         times: group_time_types(departures),
         alerts: hd(departures).alerts
       }}
    end)
  end

  defp move_data_to_departures(section, include_wayfinding, current_time) do
    data = %{
      name: if(include_wayfinding, do: section.name, else: nil),
      arrow: if(include_wayfinding, do: section.arrow, else: nil),
      pill: section.pill,
      current_time: current_time
    }

    %{section | departures: Enum.map(section.departures, &Map.merge(&1, data))}
  end

  defp group_time_types(departures) do
    departures
    |> Enum.map(&Map.merge(%{pill: &1.pill}, get_time_representation(&1)))
    |> Enum.chunk_by(& &1.type)
    |> ungroup_arr_brd()
    |> Enum.map(fn [time | _rest] = times ->
      %{pill: time.pill, type: time.type, values: Enum.map(times, & &1.value)}
    end)
  end

  # ARR and BRD departures are never grouped together
  defp ungroup_arr_brd(grouped_times) do
    grouped_times
    |> Enum.reduce([], fn
      [%{type: :text} | _rest] = group, acc ->
        ungrouped = group |> Enum.reverse() |> Enum.map(&[&1])
        ungrouped ++ acc

      group, acc ->
        [group | acc]
    end)
    |> Enum.reverse()
  end

  defp get_time_representation(%{
         time: time,
         current_time: current_time,
         vehicle_status: vehicle_status,
         stop_type: stop_type
       }) do
    {:ok, time, _} = DateTime.from_iso8601(time)
    {:ok, current_time, _} = DateTime.from_iso8601(current_time)

    second_difference = DateTime.diff(time, current_time)
    minute_difference = round(second_difference / 60)

    cond do
      vehicle_status === :stopped_at and second_difference <= 90 ->
        %{type: :text, value: :brd}

      second_difference <= 30 ->
        if stop_type === :first_stop,
          do: %{type: :text, value: :brd},
          else: %{type: :text, value: :arr}

      minute_difference < 60 ->
        %{type: :minutes, value: minute_difference}

      true ->
        timestamp =
          time
          |> Timex.to_datetime("America/New_York")
          |> Timex.format!("{h12}:{m} {AM}")

        %{type: :timestamp, value: timestamp}
    end
  end
end
