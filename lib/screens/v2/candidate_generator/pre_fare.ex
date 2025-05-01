defmodule Screens.V2.CandidateGenerator.PreFare do
  @moduledoc false

  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.AudioOnly.{AlertsIntro, AlertsOutro, ContentSummary}
  alias Screens.V2.WidgetInstance.NormalHeader
  alias Screens.V2.WidgetInstance.ShuttleBusInfo, as: ShuttleBusInfoWidget
  alias ScreensConfig.Header.CurrentStopId
  alias ScreensConfig.{Screen, ShuttleBusInfo}
  alias ScreensConfig.Screen.PreFare

  @behaviour CandidateGenerator

  @body_right_layout {:body_right,
                      %{
                        body_right_normal: [
                          Builder.with_paging(
                            {:upper_right,
                             %{one_large: [:large], two_medium: [:medium_left, :medium_right]}},
                            4
                          ),
                          :lower_right
                        ],
                        body_right_takeover: [:full_body_right],
                        body_right_surge: [:orange_line_surge_upper, :orange_line_surge_lower]
                      }}

  @impl CandidateGenerator
  def screen_template(%Screen{app_params: %PreFare{template: :duo}}) do
    {:screen,
     %{
       screen_normal: [
         :header,
         {:body,
          %{
            body_normal: [
              {:body_left,
               %{
                 body_left_normal: [:main_content_left],
                 body_left_takeover: [:full_body_left],
                 body_left_flex: Builder.with_paging(:paged_main_content_left, 4)
               }},
              @body_right_layout
            ],
            body_takeover: [:full_body_duo]
          }}
       ],
       screen_takeover: [:full_duo_screen],
       screen_split_takeover: [:full_left_screen, :full_right_screen]
     }}
    |> Builder.build_template()
  end

  # The solo template is treated as a variant of the duo where the left screen does not exist,
  # with some differences in the available "full body/screen" slots.
  def screen_template(%Screen{app_params: %PreFare{template: :solo}}) do
    {:screen,
     %{
       screen_normal: [:header, {:body, %{body_normal: [@body_right_layout]}}],
       screen_split_takeover: [:full_right_screen]
     }}
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  # Error of "arity is too high"
  # credo:disable-for-next-line
  def candidate_instances(
        config,
        _query_params,
        now \\ DateTime.utc_now(),
        subway_status_instance_fn \\ &Widgets.SubwayStatus.subway_status_instances/2,
        reconstructed_alert_instances_fn \\ &Widgets.ReconstructedAlert.reconstructed_alert_instances/1,
        elevator_status_instance_fn \\ &Widgets.ElevatorClosures.elevator_status_instances/2,
        full_line_map_instances_fn \\ &Widgets.FullLineMap.full_line_map_instances/1,
        evergreen_content_instances_fn \\ &Widgets.Evergreen.evergreen_content_instances/1,
        commuter_rail_departures_instance_fn \\ &Widgets.CRDepartures.departures_instances/2,
        departures_instances_fn \\ &Widgets.Departures.departures_instances/2
      ) do
    [
      fn -> header_instances(config, now) end,
      fn -> subway_status_instance_fn.(config, now) end,
      fn -> reconstructed_alert_instances_fn.(config) end,
      fn -> elevator_status_instance_fn.(config, now) end,
      fn -> evergreen_content_instances_fn.(config) end,
      fn -> departures_instances_fn.(config, now) end,
      fn -> full_line_map_instances_fn.(config) end,
      fn -> commuter_rail_departures_instance_fn.(config, now) end,
      fn -> shuttle_bus_info_instances(config, now) end
    ]
    |> Task.async_stream(& &1.(), timeout: 20_000)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  def audio_only_instances(
        widgets,
        config,
        routes_fetch_fn \\ &Route.fetch/1
      ) do
    [
      fn -> content_summary_instances(widgets, config, routes_fetch_fn) end,
      fn -> alerts_intro_instances(widgets, config) end,
      fn -> alerts_outro_instances(widgets, config) end
    ]
    |> Task.async_stream(& &1.(), timeout: 20_000)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  def header_instances(
        config,
        now,
        fetch_stop_name_fn \\ &Stop.fetch_stop_name/1
      ) do
    %Screen{app_params: %PreFare{header: %CurrentStopId{stop_id: stop_id}}} = config

    stop_name = fetch_stop_name_fn.(stop_id)

    [%NormalHeader{screen: config, text: stop_name, time: now}]
  end

  def shuttle_bus_info_instances(
        %Screen{
          app_params: %PreFare{
            shuttle_bus_info: %ShuttleBusInfo{
              enabled: false
            }
          }
        },
        _now
      ) do
    []
  end

  def shuttle_bus_info_instances(config, now) do
    [%ShuttleBusInfoWidget{screen: config, now: now}]
  end

  defp content_summary_instances(widgets, config, routes_fetch_fn) do
    %{stop_id: config.app_params.content_summary.parent_station_id}
    |> routes_fetch_fn.()
    |> case do
      {:ok, routes_at_station} ->
        subway_lines_at_station =
          routes_at_station
          |> Enum.map(& &1.id)
          |> Enum.map(fn
            "Red" -> :red
            "Orange" -> :orange
            "Green" <> _ -> :green
            "Blue" -> :blue
            _ -> nil
          end)
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()

        %ContentSummary{
          screen: config,
          widgets_snapshot: widgets,
          lines_at_station: subway_lines_at_station
        }

      :error ->
        nil
    end
    |> List.wrap()
  end

  defp alerts_intro_instances(widgets, config) do
    [%AlertsIntro{screen: config, widgets_snapshot: widgets}]
  end

  defp alerts_outro_instances(widgets, config) do
    [%AlertsOutro{screen: config, widgets_snapshot: widgets}]
  end
end
