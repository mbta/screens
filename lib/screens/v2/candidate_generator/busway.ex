defmodule Screens.V2.CandidateGenerator.Busway do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.NormalHeader
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Busway
  alias ScreensConfig.V2.Header.CurrentStopName

  @behaviour CandidateGenerator

  @instance_fns [
    &Widgets.Departures.departures_instances/2,
    &Widgets.Evergreen.evergreen_content_instances/2
  ]

  @impl CandidateGenerator
  def screen_template(_screen) do
    {
      :screen,
      %{
        normal: [:header, :main_content],
        takeover: [:full_screen]
      }
    }
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  def candidate_instances(
        config,
        _query_params,
        now \\ DateTime.utc_now(),
        instance_fns \\ @instance_fns
      ) do
    [(&header_instances/2) | instance_fns]
    |> Task.async_stream(& &1.(config, now), timeout: 15_000)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []

  defp header_instances(config, now) do
    %Screen{app_params: %Busway{header: %CurrentStopName{stop_name: stop_name}}} = config
    [%NormalHeader{screen: config, icon: :logo, text: stop_name, time: now}]
  end
end
