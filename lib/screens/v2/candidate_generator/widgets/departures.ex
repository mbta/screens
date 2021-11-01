defmodule Screens.V2.CandidateGenerator.Widgets.Departures do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.Departures.Filter.RouteDirection
  alias Screens.Config.V2.Departures.{Filter, Query, Section}
  alias Screens.Config.V2.{BusEink, BusShelter, Departures, GlEink, Solari, SolariLarge}
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, OvernightDepartures}

  def departures_instances(
        %Screen{app_params: %app{}} = config,
        fetch_section_departures_fn \\ &fetch_section_departures/1,
        post_processing_fn \\ fn sections, _config -> sections end
      )
      when app in [BusEink, BusShelter, GlEink, SolariLarge, Solari] do
    if Screens.Config.State.mode_disabled?(get_devops_mode(config)) do
      [%DeparturesNoData{screen: config, show_alternatives?: false}]
    else
      do_departures_instances(config, fetch_section_departures_fn, post_processing_fn)
    end
  end

  def fetch_section_departures(%Section{query: query, filter: filter}) do
    query
    |> fetch_departures()
    |> filter_departures(filter)
  end

  defp do_departures_instances(
         %{app_params: %{departures: %Departures{sections: sections}}} = config,
         fetch_section_departures_fn,
         post_processing_fn
       ) do
    sections_data =
      sections
      |> Task.async_stream(fetch_section_departures_fn, timeout: :infinity)
      |> Enum.map(fn {:ok, data} -> data end)
      |> post_processing_fn.(config)

    IO.inspect(sections_data)

    departures_instance =
      cond do
        Enum.any?(sections_data, &(&1 == :error)) ->
          %DeparturesNoData{screen: config, show_alternatives?: true}

        sections_data == [:overnight] ->
          %OvernightDepartures{screen: config}

        true ->
          sections =
            Enum.map(sections_data, fn {:ok, departures} ->
              %{type: :normal_section, rows: departures}
            end)

          %DeparturesWidget{screen: config, section_data: sections}
      end

    [departures_instance]
  end

  defp fetch_departures(%Query{opts: opts, params: params}) do
    fetch_opts =
      opts
      |> Map.from_struct()
      |> Keyword.new()

    fetch_params = Map.from_struct(params)

    Departure.fetch(fetch_params, fetch_opts)
  end

  def filter_departures(:error, _), do: :error

  def filter_departures({:ok, departures}, %Filter{
        action: :include,
        route_directions: route_directions
      }) do
    {:ok, Enum.filter(departures, &departure_in_route_directions?(&1, route_directions))}
  end

  def filter_departures({:ok, departures}, %Filter{
        action: :exclude,
        route_directions: route_directions
      }) do
    {:ok, Enum.reject(departures, &departure_in_route_directions?(&1, route_directions))}
  end

  def filter_departures({:ok, departures}, nil) do
    {:ok, departures}
  end

  def departure_in_route_directions?(d, route_directions) do
    route_direction(d) in route_directions
  end

  defp route_direction(d) do
    %RouteDirection{route_id: Departure.route_id(d), direction_id: Departure.direction_id(d)}
  end

  defp get_devops_mode(%Screen{app_id: :bus_shelter_v2}), do: :bus
  defp get_devops_mode(%Screen{app_id: :bus_eink_v2}), do: :bus
  defp get_devops_mode(%Screen{app_id: :gl_eink_v2}), do: :light_rail
  defp get_devops_mode(_), do: nil
end
