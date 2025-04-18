defmodule Screens.V2.CandidateGenerator.DupNew.Header do
  @moduledoc false

  alias Screens.V2.WidgetInstance.NormalHeader
  alias ScreensConfig.Header.{CurrentStopId, CurrentStopName}
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.Dup

  import Screens.Inject

  @stop injected(Screens.Stops.Stop)

  @spec instances(Screen.t(), DateTime.t()) :: [NormalHeader.t()]
  def instances(%Screen{app_params: %Dup{header: header_config}} = config, now) do
    # Generate one header for each of the 3 rotations.
    %NormalHeader{screen: config, icon: :logo, text: stop_name(header_config), time: now}
    |> List.duplicate(3)
  end

  defp stop_name(%CurrentStopName{stop_name: name}), do: name
  defp stop_name(%CurrentStopId{stop_id: stop_id}), do: @stop.fetch_stop_name(stop_id)
end
