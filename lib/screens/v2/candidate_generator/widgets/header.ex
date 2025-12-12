defmodule Screens.V2.CandidateGenerator.Widgets.Header do
  @moduledoc "Shared logic for generating the `NormalHeader` widget from configuration."

  alias Screens.V2.WidgetInstance.NormalHeader
  alias ScreensConfig.{Header, Screen}
  alias ScreensConfig.Screen.{Busway, Dup}

  import Screens.Inject
  @stop injected(Screens.Stops.Stop)

  @spec instances(Screen.t(), DateTime.t()) :: [NormalHeader.t()]
  def instances(%Screen{app_params: %app{header: header} = app_params} = screen, time) do
    case text(header) do
      nil ->
        []

      text ->
        List.duplicate(
          %NormalHeader{
            audio_text: audio_text(header),
            icon: icon(app_params),
            screen: screen,
            text: text,
            time: time
          },
          copies(app)
        )
    end
  end

  defp copies(Dup), do: 3
  defp copies(_app), do: 1

  defp icon(%Busway{include_logo_in_header: true}), do: :logo
  defp icon(%Dup{}), do: :logo
  defp icon(_app_params), do: nil

  defp audio_text(%Header.StopName{read_as: read_as}), do: read_as
  defp audio_text(%Header.StopId{read_as: read_as}), do: read_as

  defp text(%Header.StopName{stop_name: name}), do: name
  defp text(%Header.StopId{stop_id: stop_id}), do: @stop.fetch_stop_name(stop_id)
end
