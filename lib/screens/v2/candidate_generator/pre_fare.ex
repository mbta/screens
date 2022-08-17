defmodule Screens.V2.CandidateGenerator.PreFare do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.Config.V2.PreFare
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.AudioOnly.{AlertsIntro, AlertsOutro, ContentSummary}
  alias Screens.V2.WidgetInstance.NormalHeader

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
              {:body_left,
               %{
                 body_left_normal: [:main_content_left],
                 body_left_takeover: [:full_body_left]
               }},
              {:body_right,
               %{
                 body_right_normal: [
                   :upper_right,
                   Builder.with_paging(
                     {:lower_right,
                      %{
                        one_large: [:large],
                        two_medium: [:medium_left, :medium_right]
                      }},
                     4
                   )
                 ],
                 body_right_takeover: [:full_body_right],
                 body_right_surge: [
                   :orange_line_surge_upper,
                   :orange_line_surge_lower
                 ]
               }}
            ],
            body_takeover: [:full_body]
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
        subway_status_instance_fn \\ &Widgets.SubwayStatus.subway_status_instances/1,
        reconstructed_alert_instances_fn \\ &Widgets.ReconstructedAlert.reconstructed_alert_instances/1,
        elevator_status_instance_fn \\ &Widgets.ElevatorClosures.elevator_status_instances/2,
        full_line_map_instances_fn \\ &Widgets.FullLineMap.full_line_map_instances/1,
        evergreen_content_instances_fn \\ &Widgets.Evergreen.evergreen_content_instances/1
      ) do
    [
      fn -> header_instances(config, now) end,
      fn -> subway_status_instance_fn.(config) end,
      fn -> reconstructed_alert_instances_fn.(config) end,
      fn -> elevator_status_instance_fn.(config, now) end,
      fn -> full_line_map_instances_fn.(config) end,
      fn -> evergreen_content_instances_fn.(config) end
    ]
    |> Task.async_stream(& &1.(), ordered: false, timeout: :infinity)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  def audio_only_instances(
        widgets,
        config,
        fetch_routes_by_stop_fn \\ &Route.fetch_routes_by_stop/1
      ) do
    [
      fn -> content_summary_instances(widgets, config, fetch_routes_by_stop_fn) end,
      fn -> alerts_intro_instances(widgets, config) end,
      fn -> alerts_outro_instances(widgets, config) end
    ]
    |> Task.async_stream(& &1.(), ordered: false, timeout: :infinity)
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

  defp content_summary_instances(widgets, config, fetch_routes_by_stop_fn) do
    config.app_params.content_summary.parent_station_id
    |> fetch_routes_by_stop_fn.()
    |> case do
      {:ok, routes_at_station} ->
        subway_lines_at_station =
          routes_at_station
          |> Enum.map(& &1.route_id)
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
