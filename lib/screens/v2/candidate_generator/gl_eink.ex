defmodule Screens.V2.CandidateGenerator.GlEink do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.{BottomScreenFiller, FareInfoFooter, NormalHeader}
  alias ScreensConfig.{Departures, Footer, Header}
  alias ScreensConfig.Departures.{Query, Section}
  alias ScreensConfig.Departures.Query.Params
  alias ScreensConfig.{FreeTextLine, Screen}
  alias ScreensConfig.Screen.GlEink

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template(_screen) do
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
            # This layout variant is necessary for the DeparturesNoData widget
            # to take up both the usual main_content slot, and the left_sidebar
            # slot to its left, while still allowing the normal flex zone
            # to appear on the bottom screen.
            top_takeover: [
              :full_body_top_screen,
              Builder.with_paging({:flex_zone, %{one_medium: [:medium]}}, 2),
              :footer
            ],
            # This layout allows takeover alerts (or other non-fullscreen takeover content)
            # to be paired with filler content on the bottom screen.
            body_takeover: [
              :full_body_top_screen,
              :full_body_bottom_screen
            ],
            flex_zone_takeover: [
              :left_sidebar,
              :main_content,
              :flex_zone_takeover,
              :footer
            ],
            bottom_takeover: [
              :left_sidebar,
              :main_content,
              :full_body_bottom_screen
            ],
            top_and_flex_takeover: [
              :full_body_top_screen,
              :flex_zone_takeover,
              :footer
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
        line_map_instances_fn \\ &__MODULE__.LineMap.instances/2,
        departures_instances_fn \\ &Widgets.Departures.departures_instances/3,
        alert_instances_fn \\ &Widgets.Alerts.alert_instances/1,
        evergreen_content_instances_fn \\ &Widgets.Evergreen.evergreen_content_instances/1,
        subway_status_instances_fn \\ &Widgets.SubwayStatus.subway_status_instances/2
      ) do
    [
      fn -> header_instances(config, now, fetch_destination_fn) end,
      fn ->
        departures_instances_fn.(config, now, post_process_fn: &departures_post_processing/2)
      end,
      fn -> alert_instances_fn.(config) end,
      fn -> footer_instances(config) end,
      fn -> line_map_instances_fn.(config, now) end,
      fn -> evergreen_content_instances_fn.(config) end,
      fn -> bottom_screen_filler_instances(config) end,
      fn -> subway_status_instances_fn.(config, now) end
    ]
    |> Task.async_stream(& &1.(), timeout: 30_000)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []

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

  def footer_instances(%Screen{app_params: %GlEink{footer: %Footer{stop_id: stop_id}}}) do
    [%FareInfoFooter{mode: :subway, stop_id: stop_id}]
  end

  defp bottom_screen_filler_instances(config) do
    [%BottomScreenFiller{screen: config}]
  end

  defp departures_post_processing(fetch_result, config) do
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

    case fetch_result do
      {:ok, departures} when length(departures) <= 1 ->
        format_headway(route_id, stop_id, direction_id, departures)

      {:ok, departures} ->
        {:ok, departures}

      # Show headway instead of nothing when API fetch fails
      :error ->
        format_headway(route_id, stop_id, direction_id)
    end
  end

  defp format_headway(route_id, stop_id, direction_id, departures_to_concat \\ []) do
    destination = fetch_destination(route_id, direction_id)

    case __MODULE__.Headways.by_route_id(route_id, stop_id, direction_id, nil) do
      nil ->
        :overnight

      headway ->
        {
          :ok,
          departures_to_concat ++
            [
              %FreeTextLine{
                icon: nil,
                text: [
                  "Trains to #{destination} every",
                  %{format: :bold, text: "#{headway - 2}-#{headway + 2}"},
                  "minutes"
                ]
              }
            ]
        }
    end
  end
end
