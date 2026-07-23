defmodule Screens.V2.CandidateGenerator.PreFare do
  @moduledoc false

  alias Screens.Routes.Route
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.AudioOnly.{AlertsIntro, AlertsOutro, ContentSummary}
  alias Screens.V2.WidgetInstance.ReconstructedAlert
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.PreFare

  @behaviour CandidateGenerator

  @instance_fns [
    &Widgets.Header.instances/2,
    &Widgets.SubwayStatus.subway_status_instances/2,
    &Widgets.ReconstructedAlert.reconstructed_alert_instances/2,
    &CandidateGenerator.PreFare.ElevatorStatus.instances/2,
    &Widgets.FullLineMap.full_line_map_instances/2,
    &Widgets.Evergreen.evergreen_content_instances/2,
    &Widgets.RealtimeDepartures.departures_instances/2,
    &Widgets.EmergencyTakeover.emergency_takeover_instances/2
  ]

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
                        body_right_takeover: [:full_body_right]
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
  def candidate_instances(config, now \\ DateTime.utc_now(), instance_fns \\ @instance_fns) do
    instance_fns
    |> CandidateGenerator.async_stream(& &1.(config, now), timeout: 15_000)
    |> simplify_flex_zone()
  end

  @spec simplify_flex_zone([WidgetInstance.t()]) :: [WidgetInstance.t()]
  defp simplify_flex_zone(widgets) do
    # If multiple reconstructed alerts would compete for the flex zone, drop (down/up)stream alerts
    # to spend more time showing Subway Status (which gives a better line-wide overview).
    # Alerts with other locations (inside, boundaries) should still be shown.
    flex_zone_alert_count =
      widgets
      |> Enum.filter(&flex_zone_reconstructed_alert?/1)
      |> length()

    if flex_zone_alert_count > 1 do
      Enum.reject(widgets, fn widget ->
        flex_zone_reconstructed_alert?(widget) and downstream_or_upstream_alert?(widget)
      end)
    else
      widgets
    end
  end

  @spec flex_zone_reconstructed_alert?(WidgetInstance.t()) :: boolean()
  defp flex_zone_reconstructed_alert?(%ReconstructedAlert{} = widget) do
    :large in WidgetInstance.slot_names(widget)
  end

  defp flex_zone_reconstructed_alert?(_), do: false

  @spec downstream_or_upstream_alert?(ReconstructedAlert.t()) :: boolean()
  defp downstream_or_upstream_alert?(%ReconstructedAlert{
         alert: alert,
         location_context: location_context,
         is_terminal_station: is_terminal_station
       }) do
    LocalizedAlert.location(
      %{alert: alert, location_context: location_context},
      is_terminal_station
    ) in [:downstream, :upstream]
  end

  @impl CandidateGenerator
  def audio_only_instances(widgets, config, routes_fetch_fn \\ &Route.fetch/1) do
    # If there is any kind of full-screen takeover or evergreen content configured for a full-body
    # takeover slot, certain audio widgets may not be applicable or would give inaccurate info.
    non_takeover_instance_fns =
      if has_takeover?(widgets),
        do: [],
        else: [
          fn -> content_summary_instances(widgets, config, routes_fetch_fn) end,
          fn -> alerts_intro_instances(widgets, config) end
        ]

    (non_takeover_instance_fns ++ [fn -> alerts_outro_instances(widgets, config) end])
    |> Task.async_stream(& &1.(), timeout: 20_000)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  defp content_summary_instances(widgets, config, routes_fetch_fn) do
    case routes_fetch_fn.(%{stop_id: config.app_params.content_summary.parent_station_id}) do
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

        [
          %ContentSummary{
            screen: config,
            widgets_snapshot: widgets,
            lines_at_station: subway_lines_at_station
          }
        ]

      :error ->
        []
    end
  end

  defp alerts_intro_instances(widgets, config) do
    [%AlertsIntro{screen: config, widgets_snapshot: widgets}]
  end

  defp alerts_outro_instances(widgets, config) do
    [%AlertsOutro{screen: config, widgets_snapshot: widgets}]
  end

  @takeover_slots MapSet.new(~w[
      full_body_duo
      full_body_left
      full_body_right
      full_duo_screen
      full_left_screen
      full_right_screen
    ]a)

  defp has_takeover?(widgets) do
    widgets
    |> Enum.flat_map(&WidgetInstance.slot_names/1)
    |> Enum.any?(&(&1 in @takeover_slots))
  end
end
