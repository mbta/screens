defmodule Screens.V2.CandidateGenerator.Helpers do
  @moduledoc false

  alias Screens.Config.{Gl, Screen}
  alias Screens.V2.WidgetInstance.NormalHeader

  def gl_header_instances(config, now, fetch_destination_fn) do
    %Screen{app_params: %Gl{route_id: route_id, direction_id: direction_id}} = config

    icons_by_route_id = %{
      "Green-B" => :green_b,
      "Green-C" => :green_c,
      "Green-D" => :green_d,
      "Green-E" => :green_e
    }

    icon = Map.get(icons_by_route_id, route_id)

    case fetch_destination_fn.(route_id, direction_id) do
      nil -> []
      destination -> [%NormalHeader{screen: config, text: destination, icon: icon, time: now}]
    end
  end

  def fetch_destination(route_id, direction_id) do
    case Screens.Routes.Route.by_id(route_id) do
      {:ok, %{direction_destinations: destinations}} ->
        Enum.at(destinations, direction_id)

      _ ->
        nil
    end
  end
end
