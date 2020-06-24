defmodule Screens.SolariScreenData do
  @moduledoc false

  alias Screens.Departures.Departure
  alias Screens.LogScreenData

  def by_screen_id(screen_id, is_screen, datetime \\ nil) do
    %{
      station_name: station_name,
      sections: sections,
      section_headers: section_headers,
      overhead: overhead
    } =
      :screens
      |> Application.get_env(:screen_data)
      |> Map.get(screen_id)

    current_time =
      case datetime do
        nil -> DateTime.utc_now()
        dt -> dt
      end

    psa_name = Screens.Psa.current_psa_for(screen_id)

    sections_data = fetch_sections_data(sections, datetime)
    _ = LogScreenData.log_departures(screen_id, is_screen, sections_data)

    case sections_data do
      {:ok, data} ->
        %{
          force_reload: false,
          success: true,
          current_time: Screens.Util.format_time(current_time),
          station_name: station_name,
          sections: data,
          section_headers: section_headers,
          psa_name: psa_name,
          overhead: overhead
        }

      :error ->
        %{force_reload: false, success: false}
    end
  end

  defp fetch_sections_data(sections, datetime) do
    sections_data = Enum.map(sections, &fetch_section_data(&1, datetime))

    if Enum.any?(sections_data, fn data -> data == :error end) do
      :error
    else
      {:ok, Enum.map(sections_data, fn {:ok, data} -> data end)}
    end
  end

  defp fetch_section_data(
         %{
           name: section_name,
           arrow: arrow,
           query: %{params: query_params, opts: query_opts},
           layout: layout_params,
           pill: pill
         },
         datetime
       ) do
    case query_data(query_params, query_opts, datetime) do
      {:ok, data} ->
        {:ok,
         %{
           name: section_name,
           arrow: arrow,
           pill: pill,
           departures: do_layout(data, layout_params),
           paging: do_paging(layout_params)
         }}

      :error ->
        :error
    end
  end

  defp do_paging({:upcoming, %{paged: true, visible_rows: visible_rows}}) do
    %{is_enabled: true, visible_rows: visible_rows}
  end

  defp do_paging(_) do
    %{is_enabled: false}
  end

  def query_data(query_params, query_opts, datetime) do
    if is_nil(datetime) do
      Departure.fetch(query_params, query_opts)
    else
      Departure.fetch_schedules_by_datetime(query_params, datetime)
    end
  end

  defp do_layout(query_data, {:upcoming, %{num_rows: num_rows} = layout_opts}) do
    query_data
    |> filter_by_routes(layout_opts)
    |> filter_by_minutes(layout_opts)
    |> Enum.sort_by(& &1.time)
    |> Enum.take(num_rows)
    |> Enum.map(&Map.from_struct/1)
  end

  defp do_layout(query_data, {:bidirectional, layout_opts}) do
    query_data
    |> filter_by_routes(layout_opts)
    |> filter_by_minutes(layout_opts)
    |> Enum.sort_by(& &1.time)
    |> Enum.split_with(fn %{direction_id: direction_id} -> direction_id == 0 end)
    |> Tuple.to_list()
    |> Enum.flat_map(&Enum.slice(&1, 0, 1))
    |> Enum.sort_by(& &1.time)
    |> Enum.map(&Map.from_struct/1)
  end

  defp do_layout(query_data, :bidirectional) do
    do_layout(query_data, {:bidirectional, %{}})
  end

  defp filter_by_minutes(query_data, %{max_minutes: max_minutes}) do
    max_departure_time = DateTime.add(DateTime.utc_now(), 60 * max_minutes)

    Enum.reject(query_data, fn %{time: time_str} ->
      {:ok, departure_time, _} = DateTime.from_iso8601(time_str)
      DateTime.compare(departure_time, max_departure_time) == :gt
    end)
  end

  defp filter_by_minutes(query_data, _), do: query_data

  defp filter_by_routes(query_data, %{routes: {action, routes}}) do
    route_matchers = routes |> Enum.flat_map(&route_direction_tuple/1) |> MapSet.new()

    filter_fn =
      case action do
        :include -> &Enum.filter/2
        :exclude -> &Enum.reject/2
      end

    filter_fn.(query_data, fn departure ->
      MapSet.member?(route_matchers, {departure.route_id, departure.direction_id})
    end)
  end

  defp filter_by_routes(query_data, _), do: query_data

  defp route_direction_tuple({_, _} = route_id_and_direction), do: [route_id_and_direction]
  defp route_direction_tuple(route_id), do: [{route_id, 0}, {route_id, 1}]
end
