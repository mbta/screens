defmodule Screens.V2.CandidateGenerator.Helpers.Departures do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.Departures.Filter.RouteDirection
  alias Screens.Config.V2.Departures.{Filter, Query, Section}
  alias Screens.Config.V2.{BusEink, BusShelter, Departures, GlEink, Solari, SolariLarge}
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.DeparturesNoData

  def departures_instances(
        %Screen{app_params: %app{departures: %Departures{sections: sections}}} = config,
        fetch_section_departures_fn \\ &fetch_section_departures/1
      )
      when app in [BusEink, BusShelter, GlEink, SolariLarge, Solari] do
    sections_data =
      sections
      |> Task.async_stream(fetch_section_departures_fn)
      |> Enum.map(fn {:ok, data} -> data end)

    departures_instance =
      if Enum.any?(sections_data, &(&1 == :error)) do
        %DeparturesNoData{screen: config}
      else
        sections =
          Enum.map(sections_data, fn {:ok, departures} ->
            %{type: :normal_section, departures: departures}
          end)

        %DeparturesWidget{screen: config, section_data: sections}
      end

    [departures_instance]
  end

  defp fetch_section_departures(%Section{query: query, filter: filter}) do
    query
    |> fetch_departures()
    |> filter_departures(filter)
  end

  defp fetch_departures(%Query{opts: opts, params: params}) do
    fetch_opts =
      opts
      |> Map.from_struct()
      |> Keyword.new()

    Departure.fetch(params, fetch_opts)
  end

  defp filter_departures(:error, _), do: :error

  defp filter_departures({:ok, departures}, %Filter{
         action: :include,
         route_directions: route_directions
       }) do
    {:ok, Enum.filter(departures, &departure_in_route_directions?(&1, route_directions))}
  end

  defp filter_departures({:ok, departures}, %Filter{
         action: :exclude,
         route_directions: route_directions
       }) do
    {:ok, Enum.reject(departures, &departure_in_route_directions?(&1, route_directions))}
  end

  defp departure_in_route_directions?(d, route_directions) do
    %RouteDirection{route_id: Departure.route_id(d), direction_id: Departure.direction_id(d)} in route_directions
  end
end
