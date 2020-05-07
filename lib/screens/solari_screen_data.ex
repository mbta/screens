defmodule Screens.SolariScreenData do
  @moduledoc false

  def by_screen_id(screen_id, _is_screen) do
    %{station_name: station_name, sections: sections} =
      :screens
      |> Application.get_env(:screen_data)
      |> Map.get(screen_id)

    section_data = Enum.map(sections, &fetch_section_data/1)

    %{
      force_reload: false,
      success: true,
      current_time: Screens.Util.format_time(DateTime.utc_now()),
      station_name: station_name,
      sections: section_data
    }
  end

  defp fetch_section_data(%{
         name: section_name,
         arrow: arrow,
         query: query_params,
         layout: layout_params
       }) do
    case query_data(query_params) do
      {:ok, data} ->
        %{
          name: section_name,
          arrow: arrow,
          departures: do_layout(data, layout_params)
        }

      :error ->
        %{force_reload: false, success: false}
    end
  end

  defp query_data(query_params) do
    Screens.Departures.Departure.fetch(query_params)
  end

  defp do_layout(query_data, {:upcoming, %{num_rows: num_rows}}) do
    query_data
    |> Enum.take(num_rows)
    |> Enum.map(&Screens.Departures.Departure.to_map/1)
  end

  defp do_layout(query_data, :bidirectional) do
    query_data
    |> Enum.split_with(fn %{direction_id: direction_id} -> direction_id == 0 end)
    |> Tuple.to_list()
    |> Enum.flat_map(&Enum.slice(&1, 0, 1))
    |> Enum.sort_by(& &1.time)
    |> Enum.map(&Screens.Departures.Departure.to_map/1)
  end
end
