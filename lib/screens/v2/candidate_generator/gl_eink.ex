defmodule Screens.V2.CandidateGenerator.GlEink do
  @moduledoc false

  alias Screens.Config.{Screen, V2}
  alias Screens.Config.V2.{Footer, GlEink, Header}
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.WidgetInstance.{FareInfoFooter, LineMap, NormalHeader, Placeholder}

  @scheduled_terminal_departure_lookback_seconds 180

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       normal: [
         :header,
         :left_sidebar,
         :main_content,
         :medium_flex,
         :footer
       ],
       bottom_takeover: [
         :header,
         :left_sidebar,
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
        fetch_destination_fn \\ &fetch_destination/2,
        departures_instances_fn \\ &Widgets.Departures.departures_instances/1,
        alert_instances_fn \\ &Widgets.Alerts.alert_instances/1
      ) do
    [
      fn -> header_instances(config, now, fetch_destination_fn) end,
      fn -> departures_instances_fn.(config) end,
      fn -> alert_instances_fn.(config) end,
      fn -> footer_instances(config) end,
      fn -> placeholder_instances() end,
      fn -> line_map_instances(config) end
    ]
    |> Task.async_stream(& &1.(), ordered: false)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  def line_map_instances(
        %Screen{
          app_params: %GlEink{
            line_map: %V2.LineMap{
              station_id: station_id,
              direction_id: direction_id,
              route_id: route_id
            }
          }
        } = config
      ) do
    {:ok, stops} = RoutePattern.stops_by_route_and_direction(route_id, direction_id)

    {:ok, departures} =
      Screens.V2.Departure.fetch(%{stop_ids: [station_id], direction_id: direction_id},
        include_schedules: true,
        now: DateTime.add(DateTime.utc_now(), -@scheduled_terminal_departure_lookback_seconds)
      )

    [%LineMap{screen: config, stops: stops, departures: departures}]
  end

  def header_instances(config, now, fetch_destination_fn) do
    %Screen{
      app_params: %GlEink{
        header: %Header.Destination{route_id: route_id, direction_id: direction_id}
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

  defp placeholder_instances do
    [
      %Placeholder{color: :blue, slot_names: [:main_content]},
      %Placeholder{color: :green, slot_names: [:medium_flex]}
    ]
  end
end
