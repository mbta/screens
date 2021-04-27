defmodule Screens.V2.CandidateGenerator.GlEink do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.{Footer, GlEink, Header}
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.WidgetInstance.{FareInfoFooter, NormalHeader, Placeholder}

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       normal: [
         :header,
         :main_content,
         :medium_flex,
         :footer
       ],
       bottom_takeover: [
         :header,
         :main_content,
         :bottom_screen
       ],
       full_takeover: [:full_screen]
     }}
  end

  @impl CandidateGenerator
  def candidate_instances(
        config,
        now \\ DateTime.utc_now(),
        fetch_destination_fn \\ &fetch_destination/2
      ) do
    header_instances(config, now, fetch_destination_fn) ++
      footer_instances(config) ++
      [
        %Placeholder{color: :blue, slot_names: [:main_content]},
        %Placeholder{color: :green, slot_names: [:medium_flex]}
      ]
  end

  def header_instances(config, now, fetch_destination_fn) do
    %Screen{
      app_params: %GlEink{
        header: %Header{type: :destination, route_id: route_id, direction_id: direction_id}
      }
    } = config

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

  defp fetch_destination(route_id, direction_id) do
    case Screens.Routes.Route.by_id(route_id) do
      {:ok, %{direction_destinations: destinations}} ->
        Enum.at(destinations, direction_id)

      _ ->
        nil
    end
  end

  defp footer_instances(config) do
    %Screen{
      app_params: %GlEink{footer: %Footer{stop_id: stop_id}}
    } = config

    [
      %FareInfoFooter{
        screen: config,
        mode: :subway,
        text: "For real-time predictions and fare purchase locations:",
        url: "mbta.com/stops/#{stop_id}"
      }
    ]
  end
end
