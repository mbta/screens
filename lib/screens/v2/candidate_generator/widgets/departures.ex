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
          post_process_fn: ([Departure.result()], Screen.t() -> [Departure.result() | :overnight])
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
      |> Task.async_stream(&fetch_section_departures(&1, departure_fetch_fn), timeout: 30_000)
      |> Enum.map(fn {:ok, result} -> result end)
      |> post_process_fn.(config)

    departures_instance =
      cond do
        Enum.any?(sections_data, &(&1 == :error)) ->
          %DeparturesNoData{screen: config, show_alternatives?: true}

        sections_data == [:overnight] ->
          %OvernightDepartures{}

        sections_data == [ok: []] and app_id == :bus_eink_v2 ->
          %DeparturesNoService{screen: config}

        true ->
          sections =
            Enum.map(sections_data, fn {:ok, departures} ->
              %{type: :normal_section, rows: departures}
            end)

          %DeparturesWidget{screen: config, section_data: sections}
      end

    [departures_instance]
  end

  @spec fetch_section_departures(Section.t()) :: Departure.result()
  @spec fetch_section_departures(Section.t(), Departure.fetch()) :: Departure.result()
  def fetch_section_departures(
        %Section{
          query: %Query{opts: opts, params: params},
          filters: filters,
          bidirectional: is_bidirectional
        },
        departure_fetch_fn \\ &Departure.fetch/2
      ) do
    fetch_params = Map.from_struct(params)
    fetch_opts = opts |> Map.from_struct() |> Keyword.new()

    with {:ok, departures} <- departure_fetch_fn.(fetch_params, fetch_opts) do
      {:ok, departures |> filter_departures(filters) |> make_bidirectional(is_bidirectional)}
    end
  end

  defp filter_departures(departures, %Filters{route_directions: route_directions}) do
    filter_by_route_direction(departures, route_directions)
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
