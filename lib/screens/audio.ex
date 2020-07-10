defmodule Screens.Audio do
  @moduledoc false

  require Logger

  alias Screens.Psa
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
      {:ok, %{body: audio_data}} ->
        {:ok, audio_data}

      {:error, reason} ->
        _ = Logger.error("Failed to synthesize speech", ssml_string: ssml_string, reason: reason)
        :error
    end
  end

  def from_api_data(
        %{
          station_name: station_name,
          sections: sections,
          current_time: current_time
        },
        screen_id
      ) do
    %{
      station_name: station_name,
      departures_by_pill: group_departures_by_pill(sections, current_time),
      psa: Psa.current_audio_psa_for(screen_id)
    }
  end

  @spec group_departures_by_pill(list(map()), String.t()) ::
          keyword([departure_group()])
  defp group_departures_by_pill(sections, current_time) do
    sections
    |> Enum.map(&move_data_to_departures(&1, current_time))
    |> Util.group_by_with_order(& &1.pill)
    |> Enum.map(fn {pill, sections} -> {pill, merge_section_departures(sections)} end)
  end

  @spec merge_section_departures([map()]) :: %{
          wayfinding: String.t() | nil,
          departure_groups: [departure_group()]
        }
  defp merge_section_departures(sections) do
    sections
    |> Enum.flat_map(& &1.departures)
    |> Enum.sort_by(& &1.time)
    |> Util.group_by_with_order(&{&1.route, &1.route_id, &1.destination})
    |> Enum.map(fn {key, departures} ->
      {key,
       %{
         times: group_time_types(departures),
         alerts: hd(departures).alerts,
         wayfinding: hd(departures).wayfinding
       }}
    end)
    |> condense_wayfinding()
  end

  defp move_data_to_departures(section, current_time) do
    data = %{
      pill: section.pill,
      wayfinding: section.audio.wayfinding,
      current_time: current_time
    }

    %{section | departures: Enum.map(section.departures, &Map.merge(&1, data))}
  end

  defp group_time_types(departures) do
    departures
    |> Enum.map(&Map.merge(%{pill: &1.pill}, get_time_representation(&1)))
    |> Enum.chunk_by(& &1.type)
    |> ungroup_arr_brd()
    |> Enum.map(&time_list_to_time_group/1)
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

  defp time_list_to_time_group([time | _rest] = times) do
    %{pill: time.pill, type: time.type, values: Enum.map(times, & &1.value)}
  end

  # Don't repeat wayfinding info if it's the same for all departure groups within a pill
  defp condense_wayfinding(departure_groups) do
    unique_wayfinding =
      Enum.uniq_by(departure_groups, fn {_key, %{wayfinding: wayfinding}} -> wayfinding end)

    if length(unique_wayfinding) == 1 do
      {_key, %{wayfinding: common_wayfinding}} = hd(unique_wayfinding)

      without_wayfinding =
        Enum.map(departure_groups, fn {key, group} -> {key, %{group | wayfinding: nil}} end)

      %{
        wayfinding: common_wayfinding,
        departure_groups: without_wayfinding
      }
    else
      %{
        wayfinding: nil,
        departure_groups: departure_groups
      }
    end
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
