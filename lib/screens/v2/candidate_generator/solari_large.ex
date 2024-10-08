defmodule Screens.V2.CandidateGenerator.SolariLarge do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.{NormalHeader, Placeholder}
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Header.CurrentStopName
  alias ScreensConfig.V2.SolariLarge

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
    {:screen,
     %{
       normal: [:header, :main_content],
       takeover: [:full_screen]
     }}
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  # credo:disable-for-next-line Credo.Check.Design.DuplicatedCode
  def candidate_instances(
        config,
        now \\ DateTime.utc_now(),
        departures_instances_fn \\ &Widgets.Departures.departures_instances/2
      ) do
    [
      fn -> header_instances(config, now) end,
      fn -> departures_instances_fn.(config, now) end,
      fn -> placeholder_instances() end
    ]
    |> Task.async_stream(& &1.(), timeout: 15_000)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []

  defp header_instances(config, now) do
    %Screen{
      app_params: %SolariLarge{header: %CurrentStopName{stop_name: stop_name}}
    } = config

    [%NormalHeader{screen: config, text: stop_name, time: now}]
  end

  defp placeholder_instances do
    [
      %Placeholder{color: :blue, slot_names: [:main_content]}
    ]
  end
end
