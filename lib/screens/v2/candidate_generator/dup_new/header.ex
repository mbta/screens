defmodule Screens.V2.CandidateGenerator.DupNew.Header do
  @moduledoc false

  alias Screens.V2.WidgetInstance.NormalHeader
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Dup
  alias ScreensConfig.V2.Header.{CurrentStopId, CurrentStopName}

  @stop Application.compile_env(
          :screens,
          [Screens.V2.CandidateGenerator.DupNew, :stop_module],
          Screens.Stops.Stop
        )

  @spec instances(Screen.t(), DateTime.t()) :: [NormalHeader.t()]
  def instances(%Screen{app_params: %Dup{header: header_config}} = config, now) do
    # Generate one header for each of the 3 rotations.
    %NormalHeader{screen: config, icon: :logo, text: stop_name(header_config), time: now}
    |> List.duplicate(3)
  end

  defp stop_name(%CurrentStopName{stop_name: name}), do: name
  defp stop_name(%CurrentStopId{stop_id: stop_id}), do: @stop.fetch_stop_name(stop_id)
end
