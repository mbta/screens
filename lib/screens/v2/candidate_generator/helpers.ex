defmodule Screens.V2.CandidateGenerator.Helpers do
  @moduledoc false

  alias Screens.Config.{Gl, Screen}
  alias Screens.V2.WidgetInstance.NormalHeader

  def gl_header_instances(config) do
    %Screen{app_params: %Gl{route_id: route_id, direction_id: direction_id}} = config

    icons_by_route_id = %{
      "Green-B" => :green_b,
      "Green-C" => :green_c,
      "Green-D" => :green_d,
      "Green-E" => :green_e
    }

    case Screens.Routes.Route.by_id(route_id) do
      {:ok, %{direction_destinations: destinations}} ->
        destination = Enum.at(destinations, direction_id)
        icon = Map.get(icons_by_route_id, route_id)
        [%NormalHeader{screen: config, text: destination, icon: icon, time: DateTime.utc_now()}]

      _ ->
        []
    end
  end
end
