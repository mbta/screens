defmodule Screens.Audio do
  @moduledoc false

  @lexicon_names ["mbtalexicon"]

  def synthesize(ssml_string) do
    IO.puts(ssml_string)

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
      departures: group_departures_by_pill_and_flatten(sections, include_wayfinding, current_time)
    }
  end

  defp group_departures_by_pill_and_flatten(sections, include_wayfinding, current_time) do
    sections
    |> Enum.map(&move_data_to_departures(&1, include_wayfinding, current_time))
    |> group_by_with_order(& &1.pill)
    |> Enum.flat_map(fn {_pill, sections} -> merge_section_departures(sections) end)
  end

  defp merge_section_departures(sections) do
    sections
    |> Enum.reduce([], fn %{departures: departures}, acc -> acc ++ departures end)
    |> Enum.sort_by(& &1.time)
  end

  defp move_data_to_departures(section, include_wayfinding, current_time) do
    data = %{
      name: if(include_wayfinding, do: section.name, else: nil),
      arrow: if(include_wayfinding, do: section.arrow, else: nil),
      current_time: current_time
    }

    Map.put(section, :departures, Enum.map(section.departures, &Map.merge(&1, data)))
  end

  # Similar to Enum.group_by, except it returns a keyword list instead of a map to maintain order.
  # key_fun must always return an atom.
  def group_by_with_order(enumerable, key_fun, value_fun \\ fn x -> x end)
      when is_function(key_fun) do
    enumerable
    |> Enum.reverse()
    |> Enum.reduce([], fn entry, acc ->
      key = key_fun.(entry)
      value = value_fun.(entry)

      Keyword.put(acc, key, [value | Keyword.get(acc, key, [])])
    end)
  end
end
