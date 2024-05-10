defmodule Screens.V2.CandidateGenerator.Widgets.Departures do
  @moduledoc false

  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, DeparturesNoService, OvernightDepartures}
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Departures.Filters.RouteDirections
  alias ScreensConfig.V2.Departures.Filters.RouteDirections.RouteDirection
  alias ScreensConfig.V2.Departures.{Filters, Query, Section}
  alias ScreensConfig.V2.{BusEink, BusShelter, Busway, Departures, GlEink, SolariLarge}

  @type options :: [
          departure_fetch_fn: Departure.fetch(),
          post_process_fn: (Departure.result(), Screen.t() -> Departure.result() | :overnight)
        ]

  @type widget ::
          DeparturesNoData.t()
          | DeparturesNoService.t()
          | DeparturesWidget.t()
          | OvernightDepartures.t()

  @spec departures_instances(Screen.t()) :: [widget()]
  @spec departures_instances(Screen.t(), options()) :: [widget()]
  def departures_instances(%Screen{app_params: %app{}} = config, options \\ [])
      when app in [BusEink, BusShelter, Busway, GlEink, SolariLarge] do
    if Screens.Config.Cache.mode_disabled?(get_devops_mode(config)) do
      [%DeparturesNoData{screen: config, show_alternatives?: false}]
    else
      do_departures_instances(
        config,
        Keyword.get(options, :departure_fetch_fn, &Departure.fetch/2),
        Keyword.get(options, :post_process_fn, fn results, _config -> results end)
      )
    end
  end

  defp do_departures_instances(
         %Screen{app_params: %{departures: %Departures{sections: sections}}, app_id: app_id} =
           config,
         departure_fetch_fn,
         post_process_fn
       ) do
    sections_data =
      sections
      |> Task.async_stream(
        &%{
          section: &1,
          result: &1 |> fetch_section_departures(departure_fetch_fn) |> post_process_fn.(config)
        },
        timeout: 30_000
      )
      |> Enum.map(fn {:ok, section_data} -> section_data end)

    departures_instance =
      cond do
        Enum.any?(sections_data, &(&1.result == :error)) ->
          %DeparturesNoData{screen: config, show_alternatives?: true}

        match?([%{result: :overnight}], sections_data) ->
          %OvernightDepartures{}

        match?([%{result: {:ok, []}}], sections_data) and app_id == :bus_eink_v2 ->
          %DeparturesNoService{screen: config}

        true ->
          sections =
            Enum.map(sections_data, fn %{
                                         section: %Section{layout: layout},
                                         result: {:ok, departures}
                                       } ->
              %{type: :normal_section, rows: departures, layout: layout}
            end)

          %DeparturesWidget{screen: config, section_data: sections}
      end

    [departures_instance]
  end

  @spec fetch_section_departures(Section.t()) :: Departure.result()
  @spec fetch_section_departures(Section.t(), Departure.fetch()) :: Departure.result()
  @spec fetch_section_departures(Section.t(), Departure.fetch(), DateTime.t()) ::
          Departure.result()
  def fetch_section_departures(
        %Section{
          query: %Query{opts: opts, params: params},
          filters: filters,
          bidirectional: is_bidirectional
        },
        departure_fetch_fn \\ &Departure.fetch/2,
        now \\ DateTime.utc_now()
      ) do
    fetch_params = Map.from_struct(params)
    fetch_opts = opts |> Map.from_struct() |> Keyword.new()

    with {:ok, departures} <- departure_fetch_fn.(fetch_params, fetch_opts) do
      {:ok, departures |> filter_departures(filters, now) |> make_bidirectional(is_bidirectional)}
    end
  end

  defp filter_departures(
         departures,
         %Filters{max_minutes: max_minutes, route_directions: route_directions},
         now
       ) do
    departures
    |> filter_by_time(max_minutes, now)
    |> filter_by_route_direction(route_directions)
  end

  defp filter_by_time(departures, nil, _now), do: departures

  defp filter_by_time(departures, max_minutes, now) do
    latest_time = DateTime.add(now, max_minutes, :minute)
    Enum.reject(departures, &(DateTime.compare(Departure.time(&1), latest_time) == :gt))
  end

  defp filter_by_route_direction(departures, %RouteDirections{
         action: :include,
         targets: targets
       }) do
    Enum.filter(departures, &departure_in_route_directions?(&1, targets))
  end

  defp filter_by_route_direction(departures, %RouteDirections{
         action: :exclude,
         targets: targets
       }) do
    Enum.reject(departures, &departure_in_route_directions?(&1, targets))
  end

  defp filter_by_route_direction(departures, nil) do
    departures
  end

  defp departure_in_route_directions?(d, route_directions) do
    route_direction(d) in route_directions
  end

  defp route_direction(d) do
    %RouteDirection{route_id: Departure.route_id(d), direction_id: Departure.direction_id(d)}
  end

  # "Bidirectional" mode: take only the first departure, and the next departure in the opposite
  # direction from the first, if one exists.
  defp make_bidirectional([first | rest], true) do
    first_direction = Departure.direction_id(first)

    opposite? =
      Enum.find(rest, Enum.at(rest, 0), fn departure ->
        Departure.direction_id(departure) == 1 - first_direction
      end)

    Enum.reject([first, opposite?], &is_nil/1)
  end

  defp make_bidirectional(departures, _), do: departures

  defp get_devops_mode(%Screen{app_id: :bus_shelter_v2}), do: :bus
  defp get_devops_mode(%Screen{app_id: :bus_eink_v2}), do: :bus
  defp get_devops_mode(%Screen{app_id: :gl_eink_v2}), do: :light_rail
  defp get_devops_mode(_), do: nil
end
