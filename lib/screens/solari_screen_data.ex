defmodule Screens.SolariScreenData do
  @moduledoc false

  alias Screens.Config.{HeadwayConfig, Query, Solari, State}
  alias Screens.Config.Query.{Opts, Params}
  alias Screens.Config.Solari.Section
  alias Screens.Config.Solari.Section.Layout
  alias Screens.Config.Solari.Section.Layout.{Bidirectional, Upcoming}
  alias Screens.Departures.Departure
  alias Screens.LogScreenData
  alias Screens.SignsUiConfig

  def by_screen_id(screen_id, is_screen, datetime \\ nil) do
    %Solari{
      station_name: station_name,
      sections: sections,
      section_headers: section_headers,
      overhead: overhead,
      headway_config: headway_config
    } = State.app_params(screen_id)

    current_time =
      case datetime do
        nil -> DateTime.utc_now()
        dt -> dt
      end

    {psa_type, psa_url} = Screens.Psa.current_psa_for(screen_id)

    sections_data = fetch_sections_data(sections, datetime)
    _ = LogScreenData.log_departures(screen_id, is_screen, sections_data)

    headway_mode = fetch_headway_mode(headway_config, current_time)

    case sections_data do
      {:ok, data} ->
        %{
          force_reload: false,
          success: true,
          current_time: Screens.Util.format_time(current_time),
          station_name: station_name,
          sections: data,
          section_headers: section_headers,
          psa_type: psa_type,
          psa_url: psa_url,
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
         %Section{
           name: section_name,
           arrow: arrow,
           query: %Query{params: query_params, opts: query_opts},
           layout: layout_params,
           audio: audio_params,
           pill: pill
         },
         datetime
       ) do
    case query_data(query_params, query_opts, datetime) do
      {:ok, data} ->
        departures = do_layout(data, layout_params)

        {:ok,
         %{
           name: section_name,
           arrow: arrow,
           pill: pill,
           audio: Map.from_struct(audio_params),
           departures: departures,
           paging: do_paging(departures, layout_params)
         }}

      :error ->
        :error
    end
  end

  def fetch_headway_mode(%HeadwayConfig{headway_id: nil}, _), do: %{active: false}

  def fetch_headway_mode(%HeadwayConfig{sign_ids: sign_ids, headway_id: headway_id}, current_time) do
    if SignsUiConfig.State.all_signs_in_headway_mode?(sign_ids) do
      time_ranges = SignsUiConfig.State.time_ranges(headway_id)
      current_time_period = time_period(current_time)

      case time_ranges do
        %{^current_time_period => {range_low, range_high}} ->
          %{active: true, range_low: range_low, range_high: range_high}

        _ ->
          %{active: false}
      end
    else
      %{active: false}
    end
  end

  def time_period(utc_time) do
    {:ok, dt} = DateTime.shift_zone(utc_time, "America/New_York")
    day_of_week = dt |> DateTime.to_date() |> Date.day_of_week()

    weekday? = day_of_week in 1..5

    rush_hour? =
      (dt.hour >= 7 and dt.hour < 9) or (dt.hour >= 16 and dt.hour < 18) or
        (dt.hour == 18 and dt.minute <= 30)

    if(weekday? and rush_hour?, do: :peak, else: :off_peak)
  end

  @spec do_paging(list(map()), Layout.t()) :: map()
  defp do_paging(departures, %Upcoming{paged: true, visible_rows: :infinity}) do
    %{is_enabled: true, visible_rows: length(departures)}
  end

  defp do_paging(_departures, %Upcoming{paged: true, visible_rows: visible_rows}) do
    %{is_enabled: true, visible_rows: visible_rows}
  end

  defp do_paging(_, _) do
    %{is_enabled: false}
  end

  defp query_data(%Params{} = params, %Opts{include_schedules: include_schedules}, datetime) do
    query_params = Map.from_struct(params)

    if is_nil(datetime) do
      Departure.fetch(query_params, include_schedules)
    else
      Departure.fetch_schedules_by_datetime(query_params, datetime)
    end
  end

  @spec do_layout(list(map()), Upcoming.t()) :: list(map())
  defp do_layout(query_data, %Upcoming{num_rows: num_rows} = layout_opts) do
    query_data
    |> filter_by_routes(layout_opts)
    |> filter_by_minutes(layout_opts)
    |> Enum.sort_by(& &1.time)
    |> take_rows(num_rows)
    |> Enum.map(&Map.from_struct/1)
  end

  @spec do_layout(list(map()), Bidirectional.t()) :: list(map())
  defp do_layout(query_data, %Bidirectional{} = layout_opts) do
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

  @spec filter_by_minutes(list(map()), Layout.t()) :: list(map())
  defp filter_by_minutes(query_data, %{max_minutes: :infinity}), do: query_data

  defp filter_by_minutes(query_data, %{max_minutes: max_minutes}) do
    max_departure_time = DateTime.add(DateTime.utc_now(), 60 * max_minutes)

    Enum.reject(query_data, fn %{time: time_str} ->
      {:ok, departure_time, _} = DateTime.from_iso8601(time_str)
      DateTime.compare(departure_time, max_departure_time) == :gt
    end)
  end

  defp filter_by_minutes(query_data, _), do: query_data

  @spec filter_by_routes(list(map()), Layout.t()) :: list(map())
  defp filter_by_routes(query_data, %{routes: {action, routes}}) do
    route_matchers = MapSet.new(routes)

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

  defp take_rows(query_data, :infinity), do: query_data

  defp take_rows(query_data, num_rows) do
    Enum.take(query_data, num_rows)
  end
end
