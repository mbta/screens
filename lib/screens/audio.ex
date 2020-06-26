defmodule Screens.Audio do
  @moduledoc false

  alias Screens.Util

  @lexicon_names ["mbtalexicon"]

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
  end

  defp move_data_to_departures(section, include_wayfinding, current_time) do
    data = %{
      name: if(include_wayfinding, do: section.name, else: nil),
      arrow: if(include_wayfinding, do: section.arrow, else: nil),
      pill: section.pill,
      current_time: current_time
    }

    Map.put(section, :departures, Enum.map(section.departures, &Map.merge(&1, data)))
  end
end
