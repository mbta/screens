defmodule Screens.V2.CandidateGenerator.GlEink do
  @moduledoc false

  alias Screens.Config.Dup.Override.FreeTextLine
  alias Screens.Config.V2.Departures
  alias Screens.Config.V2.Departures.{Query, Section}
  alias Screens.Config.V2.Departures.Query.Params
  alias Screens.Config.{Screen, V2}
  alias Screens.Config.V2.{Footer, GlEink, Header}
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder

  alias Screens.V2.WidgetInstance.{
    BottomScreenFiller,
    FareInfoFooter,
    LineMap,
    NormalHeader
  }

  @scheduled_terminal_departure_lookback_seconds 180

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       screen_normal: [
         :header,
         {:body,
          %{
            body_normal: [
              :left_sidebar,
              :main_content,
              Builder.with_paging({:flex_zone, %{one_medium: [:medium]}}, 2),
              :footer
            ],
            body_takeover: [
              :full_body_top_screen,
              :full_body_bottom_screen
            ],
            bottom_takeover: [
              :left_sidebar,
              :main_content,
              :full_body_bottom_screen
            ]
          }}
       ],
       screen_takeover: [:full_screen]
     }}
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  def candidate_instances(
        config,
        now \\ DateTime.utc_now(),
        fetch_destination_fn \\ &fetch_destination/2,
        departures_instances_fn \\ &Widgets.Departures.departures_instances/3,
        alert_instances_fn \\ &Widgets.Alerts.alert_instances/1,
        evergreen_content_instances_fn \\ &Widgets.Evergreen.evergreen_content_instances/1
      ) do
    [
      fn -> header_instances(config, now, fetch_destination_fn) end,
      fn ->
        departures_instances_fn.(
          config,
          &Widgets.Departures.fetch_section_departures/1,
          &departures_post_processing/2
        )
      end,
      fn -> alert_instances_fn.(config) end,
      fn -> footer_instances(config) end,
      fn -> line_map_instances(config, now) end,
      fn -> evergreen_content_instances_fn.(config) end,
      fn -> bottom_screen_filler_instances(config) end
    ]
    |> Task.async_stream(& &1.(), ordered: false, timeout: :infinity)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []

  defp line_map_instances(
         %Screen{
           app_params: %GlEink{
             line_map: %V2.LineMap{
               station_id: station_id,
               direction_id: direction_id,
               route_id: route_id
             }
           }
         } = config,
         now,
         stops_by_route_and_direction_fn \\ &RoutePattern.stops_by_route_and_direction/2,
         fetch_departures_fn \\ &Screens.V2.Departure.fetch/2
       ) do
    {:ok, stops} = stops_by_route_and_direction_fn.(route_id, direction_id)
    {:ok, reverse_stops} = stops_by_route_and_direction_fn.(route_id, 1 - direction_id)

    {:ok, departures} =
      fetch_departures_fn.(%{stop_ids: [station_id]},
        include_schedules: true,
        now: DateTime.add(now, -@scheduled_terminal_departure_lookback_seconds)
      )

    [%LineMap{screen: config, stops: stops, reverse_stops: reverse_stops, departures: departures}]
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

  def footer_instances(config) do
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

  defp bottom_screen_filler_instances(config) do
    [%BottomScreenFiller{screen: config}]
  end

  defp departures_post_processing(sections, config) do
    %Screen{
      app_params: %GlEink{
        departures: %Departures{
          sections: [
            %Section{
              query: %Query{
                params: %Params{
                  stop_ids: [stop_id],
                  route_ids: [route_id],
                  direction_id: direction_id
                }
              }
            }
          ]
        }
      }
    } = config

    Enum.map(sections, fn
      {:ok, departures} when length(departures) <= 1 ->
        destination = fetch_destination(route_id, direction_id)

        case Screens.Headways.by_route_id(route_id, stop_id, direction_id, nil) do
          nil ->
            :overnight

          headway ->
            {:ok,
             departures ++
               [
                 %{
                   text: %FreeTextLine{
                     icon: nil,
                     text: [
                       "Trains to #{destination} every",
                       %{format: :bold, text: "#{headway - 2}-#{headway + 2}"},
                       "minutes"
                     ]
                   }
                 }
               ]}
        end

      {:ok, departures} ->
        {:ok, departures}
    end)
  end
end
