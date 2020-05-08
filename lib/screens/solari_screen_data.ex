defmodule Screens.SolariScreenData do
  @moduledoc false

  alias Screens.Departures.Departure

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
         query: %{params: query_params, opts: query_opts},
         layout: layout_params
       }) do
    case query_data(query_params, query_opts) do
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

  defp query_data(query_params, query_opts) do
    Departure.fetch(query_params, query_opts)
  end

  defp do_layout(query_data, {:upcoming, %{num_rows: num_rows} = layout_opts}) do
    query_data
    |> filter_by_routes(layout_opts)
    |> Enum.take(num_rows)
    |> Enum.map(&Departure.to_map/1)
  end

  defp do_layout(query_data, :bidirectional) do
    query_data
    |> Enum.split_with(fn %{direction_id: direction_id} -> direction_id == 0 end)
    |> Tuple.to_list()
    |> Enum.flat_map(&Enum.slice(&1, 0, 1))
    |> Enum.sort_by(& &1.time)
    |> Enum.map(&Departure.to_map/1)
  end

  defp filter_by_routes(query_data, %{routes: routes}) do
    route_matchers = Enum.map(routes, &build_route_matcher/1)

    Enum.filter(query_data, fn departure ->
      Enum.any?(route_matchers, fn match_fn -> match_fn.(departure) end)
    end)
  end

  defp filter_by_routes(query_data, _), do: query_data

  @spec build_route_matcher({String.t(), 0 | 1} | String.t()) :: (Departure.t() -> boolean())
  defp build_route_matcher({route_id, direction_id}) do
    fn %Departure{route_id: departure_route, direction_id: departure_direction} ->
      route_id == departure_route and direction_id == departure_direction
    end
  end

  defp build_route_matcher(route_id) do
    fn %Departure{route_id: departure_route} -> route_id == departure_route end
  end
end
