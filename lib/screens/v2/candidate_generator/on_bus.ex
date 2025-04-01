defmodule Screens.V2.CandidateGenerator.OnBus do
  @moduledoc false

  alias Screens.V2.CandidateGenerator
  alias Screens.V2.CandidateGenerator.Widgets.OnBus
  alias Screens.V2.Template.Builder
  alias Screens.V2.WidgetInstance.NormalHeader

  @behaviour CandidateGenerator

  @impl true
  def screen_template(_screen) do
    {
      :screen,
      %{
        screen_normal: [
          :header,
          {:body,
           %{
             body_normal: [
               :main_content
             ]
           }}
        ]
      }
    }
    |> Builder.build_template()
  end

  @impl CandidateGenerator
  def candidate_instances(
        config,
        query_params,
        now \\ DateTime.utc_now(),
        departures_instances_fn \\ &OnBus.Departures.departures_candidates/3
      ) do
    [
      fn -> departures_instances_fn.(config, query_params, now) end,
      fn -> header_instances(config, now) end
    ]
    |> Task.async_stream(& &1.())
    |> Enum.flat_map(fn {:ok, instances} -> instances end)
  end

  defp header_instances(config, now) do
    [%NormalHeader{screen: config, time: now, text: "CONNECTIONS"}]
  end

  @impl CandidateGenerator
  def audio_only_instances(_widgets, _config), do: []
end
