defmodule Screens.DupScreenData do
  @moduledoc false

  alias Screens.Config.{Dup, Dup.Primary, State}
  alias Screens.Departures.Departure
  alias Screens.LogScreenData

  @max_rows 4

  def by_screen_id(screen_id, is_screen) do
    %Dup{
      primary: %Primary{header: header, sections: sections}
    } = State.app_params(screen_id)

    current_time = DateTime.utc_now()

    sections_data = fetch_sections_data(sections)
    _ = LogScreenData.log_departures(screen_id, is_screen, sections_data)

    case sections_data do
      {:ok, data} ->
        %{
          force_reload: false,
          success: true,
          current_time: Screens.Util.format_time(current_time),
          header: header,
          sections: data
        }

      :error ->
        # FOLLOW-UP can we actually reload the DUP app without disturbing the rest of the DUP content?
        %{force_reload: true, success: false}
    end
  end

  defp fetch_sections_data(sections) do
    sections_data = Enum.map(sections, &fetch_section_data/1)

    if Enum.any?(sections_data, fn data -> data == :error end) do
      :error
    else
      {:ok, Enum.map(sections_data, fn {:ok, data} -> data end)}
    end
  end

  defp fetch_section_data(section_config) do
    case query_data(section_config) do
      {:ok, departures} -> {:ok, do_layout(departures, section_config.layout)}
      :error -> :error
    end
  end

  defp query_data(section) do
    query_params = Map.take(section, ~w[stop_ids route_ids]a)
    Departure.fetch(query_params, false)
  end

  defp do_layout(departures, :upcoming) do
    departures
    |> Enum.sort_by(& &1.time)
    |> Enum.take(@max_rows)
    |> Enum.map(&Map.from_struct/1)
  end

  defp do_layout(departures, :bidirectional) do
    departures
    |> Enum.sort_by(& &1.time)
    |> Enum.split_with(fn %{direction_id: direction_id} -> direction_id == 1 end)
    |> Tuple.to_list()
    |> Enum.flat_map(&Enum.slice(&1, 0, 1))
    |> Enum.sort_by(& &1.time)
    |> Enum.map(&Map.from_struct/1)
  end
end
