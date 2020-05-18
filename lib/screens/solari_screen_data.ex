defmodule Screens.SolariScreenData do
  @moduledoc false

  require Logger
  alias Screens.Departures.Departure

  def by_screen_id(screen_id, _is_screen, schedule \\ nil) do
    %{station_name: station_name, sections: sections, show_section_headers: show_section_headers} =
      :screens
      |> Application.get_env(:screen_data)
      |> Map.get(screen_id)

    current_time =
      case schedule do
        nil -> DateTime.utc_now()
        {_, time} -> time
      end

    case fetch_sections_data(sections, schedule) do
      {:ok, data} ->
        %{
          force_reload: false,
          success: true,
          current_time: Screens.Util.format_time(current_time),
          station_name: station_name,
          sections: data,
          show_section_headers: show_section_headers
        }

      :error ->
        %{force_reload: false, success: false}
    end
  end

  defp fetch_sections_data(sections, schedule) do
    sections_data = Enum.map(sections, &fetch_section_data(&1, schedule))

    if Enum.any?(sections_data, fn data -> data == :error end) do
      :error
    else
      {:ok, Enum.map(sections_data, fn {:ok, data} -> data end)}
    end
  end

  defp fetch_section_data(
         %{
           name: section_name,
           header_extra: header_extra,
           query: %{params: query_params, opts: query_opts},
           layout: layout_params
         } = screen_config,
         schedule
       ) do
    case query_data(query_params, query_opts, schedule) do
      {:ok, data} ->
        {:ok,
         %{
           name: section_name,
           header_extra: do_header_extra(header_extra, screen_config),
           departures: do_layout(data, layout_params),
           paging: do_paging(layout_params)
         }}

      :error ->
        _ = Logger.info("solari fetch_section_data failed to fetch #{section_name}")
        :error
    end
  end

  defp do_paging({:upcoming, %{paged: true, visible_rows: visible_rows}}) do
    %{is_enabled: true, visible_rows: visible_rows}
  end

  defp do_paging(_) do
    %{is_enabled: false}
  end

  def query_data(query_params, query_opts, schedule) do
    if is_nil(schedule) do
      Departure.fetch(query_params, query_opts)
    else
      Departure.fetch_schedules_by_date_and_time(query_params, schedule)
    end
  end

  defp do_header_extra(nil, _screen_config), do: nil

  defp do_header_extra({:arrow, direction}, _screen_config),
    do: %{content_type: :arrow, value: direction}

  defp do_header_extra(:route_count, %{layout: {:upcoming, %{routes: routes}}}),
    do: %{content_type: :route_count, value: length(routes)}

  defp do_header_extra(:route_count, %{query: %{params: %{route_ids: route_ids}}}),
    do: %{content_type: :route_count, value: length(route_ids)}

  defp do_header_extra(_, _), do: nil

  defp do_layout(query_data, {:upcoming, %{num_rows: num_rows} = layout_opts}) do
    query_data
    |> filter_by_routes(layout_opts)
    |> Enum.take(num_rows)
    |> Enum.map(&Map.from_struct/1)
  end

  defp do_layout(query_data, :bidirectional) do
    query_data
    |> Enum.split_with(fn %{direction_id: direction_id} -> direction_id == 0 end)
    |> Tuple.to_list()
    |> Enum.flat_map(&Enum.slice(&1, 0, 1))
    |> Enum.sort_by(& &1.time)
    |> Enum.map(&Map.from_struct/1)
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
