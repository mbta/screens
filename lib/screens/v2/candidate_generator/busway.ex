defmodule Screens.V2.CandidateGenerator.Busway do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.{NormalHeader, Placeholder}
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Busway
  alias ScreensConfig.V2.Header.CurrentStopName

  defmodule Deps do
    @moduledoc false
    defstruct now: &DateTime.utc_now/0,
              departures_instances: &Widgets.Departures.departures_instances/2
  end

  @behaviour CandidateGenerator

  @impl CandidateGenerator
  def screen_template do
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
  def candidate_instances(config, deps \\ %Deps{}) do
    now = deps.now.()

    [
      fn -> header_instances(config, now) end,
      fn -> deps.departures_instances.(config, now) end,
      fn -> placeholder_instances() end
    ]
    |> Task.async_stream(& &1.(), timeout: 15_000)
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []

  defp header_instances(config, now) do
    %Screen{app_params: %Busway{header: %CurrentStopName{stop_name: stop_name}}} = config

    [%NormalHeader{screen: config, icon: :logo, text: stop_name, time: now}]
  end

  defp placeholder_instances do
    [
      %Placeholder{color: :blue, slot_names: [:main_content]}
    ]
  end
end
