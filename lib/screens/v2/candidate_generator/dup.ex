defmodule Screens.V2.CandidateGenerator.Dup do
  @moduledoc false

  alias Screens.Stops.Stop
  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Dup.Alerts, as: AlertsInstances
  alias Screens.V2.CandidateGenerator.Dup.Departures, as: DeparturesInstances
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.NormalHeader
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Dup
  alias ScreensConfig.V2.Header.{CurrentStopId, CurrentStopName}

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template(_screen) do
    {:screen,
     %{
       screen_normal: [
         {:rotation_zero,
          %{
            rotation_normal_zero: [
              :header_zero,
              {:body_zero,
               %{
                 body_normal_zero: [
                   :main_content_zero
                 ],
                 body_split_zero: [
                   :main_content_reduced_zero,
                   :bottom_pane_zero
                 ]
               }}
            ],
            rotation_takeover_zero: [:full_rotation_zero]
          }},
         {:rotation_one,
          %{
            rotation_normal_one: [
              :header_one,
              {:body_one,
               %{
                 body_normal_one: [:main_content_one],
                 body_split_one: [
                   :main_content_reduced_one,
                   :bottom_pane_one
                 ]
               }}
            ],
            rotation_takeover_one: [:full_rotation_one]
          }},
         {:rotation_two,
          %{
            rotation_normal_two: [
              :header_two,
              {:body_two,
               %{
                 body_normal_two: [
                   :main_content_two
                 ],
                 body_split_two: [
                   :main_content_reduced_two,
                   :bottom_pane_two
                 ]
               }}
            ],
            rotation_takeover_two: [:full_rotation_two]
          }}
       ]
     }}
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  def candidate_instances(
        config,
        _query_params,
        now \\ DateTime.utc_now(),
        fetch_stop_name_fn \\ &Stop.fetch_stop_name/1,
        evergreen_content_instances_fn \\ &Widgets.Evergreen.evergreen_content_instances/1,
        departures_instances_fn \\ &DeparturesInstances.departures_instances/2,
        alerts_instances_fn \\ &AlertsInstances.alert_instances/2
      ) do
    Screens.Telemetry.span([:screens, :v2, :candidate_generator, :dup], fn ->
      ctx = Screens.Telemetry.context()

      [
        span_thunk(:header_instances, ctx, fn ->
          header_instances(config, now, fetch_stop_name_fn)
        end),
        span_thunk(:alerts_instances, ctx, fn -> alerts_instances_fn.(config, now) end),
        span_thunk(:departures_instances, ctx, fn -> departures_instances_fn.(config, now) end),
        span_thunk(:evergreen_content_instances, ctx, fn ->
          evergreen_content_instances_fn.(config)
        end)
      ]
      |> Task.async_stream(& &1.(), timeout: 30_000)
      |> Enum.flat_map(fn {:ok, instances} -> instances end)
    end)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []

  def header_instances(
        config,
        now,
        fetch_stop_name_fn
      ) do
    %Screen{app_params: %Dup{header: header_config}} = config

    stop_name =
      case header_config do
        %CurrentStopId{stop_id: stop_id} ->
          case fetch_stop_name_fn.(stop_id) do
            nil -> []
            stop_name -> stop_name
          end

        %CurrentStopName{stop_name: stop_name} ->
          stop_name
      end

    List.duplicate(%NormalHeader{screen: config, icon: :logo, text: stop_name, time: now}, 3)
  end

  defp span_thunk(name, meta, fun) when is_atom(name) and is_function(fun, 0) do
    fn ->
      Screens.Telemetry.span([:screens, :v2, :candidate_generator, :dup, name], meta, fun)
    end
  end
end
