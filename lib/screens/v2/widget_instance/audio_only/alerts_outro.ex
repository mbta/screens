defmodule Screens.V2.WidgetInstance.AudioOnly.AlertsOutro do
  @moduledoc """
  An audio-only widget that follows the section of the readout describing alerts.
  """

  alias Screens.Config.Screen
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.ReconstructedAlert

  require Logger

  @type t :: %__MODULE__{
          screen: Screen.t(),
          widgets_snapshot: list(WidgetInstance.t())
        }

  @enforce_keys [:screen, :widgets_snapshot]
  defstruct @enforce_keys

  # This value is appended to the target widget's sort key in order to insert this one
  # immediately after the target, and is unique among other audio-only widgets'
  # sort keys so that there is a definite ordering should two audio-only widgets
  # end up adjacent to each other.
  @audio_sort_key_part [2]

  def audio_serialize(%__MODULE__{screen: %Screen{app_id: :pre_fare_v2}}) do
    %{}
  end

  def audio_sort_key(%__MODULE__{} = t, audio_sort_key_fn \\ &WidgetInstance.audio_sort_key/1) do
    last_alert_widget =
      t.widgets_snapshot
      |> Enum.sort_by(audio_sort_key_fn, :desc)
      |> Enum.find(&alert_widget?/1)

    case last_alert_widget do
      nil ->
        Logger.warn("Failed to find an alert widget in the audio readout queue")
        [100]

      widget ->
        audio_sort_key_fn.(widget) ++ @audio_sort_key_part
    end
  end

  def audio_valid_candidate?(%__MODULE__{screen: %Screen{app_id: :pre_fare_v2}} = t) do
    Enum.any?(t.widgets_snapshot, &alert_widget?/1)
  end

  def audio_valid_candidate?(_t) do
    false
  end

  def audio_view(_instance), do: ScreensWeb.V2.Audio.AlertsOutroView

  defp alert_widget?(%ReconstructedAlert{}), do: true
  defp alert_widget?(%_other_widget_instance{}), do: false

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.AudioOnly.AlertsOutro

    # Since this is an audio-only widget, these functions will never be called.
    def priority(_instance), do: :no_render
    def serialize(_instance), do: %{}
    def slot_names(_instance), do: :no_render
    def widget_type(_instance), do: :no_render
    def valid_candidate?(_instance), do: false

    def audio_serialize(instance), do: AlertsOutro.audio_serialize(instance)
    def audio_sort_key(instance), do: AlertsOutro.audio_sort_key(instance)
    def audio_valid_candidate?(instance), do: AlertsOutro.audio_valid_candidate?(instance)
    def audio_view(instance), do: AlertsOutro.audio_view(instance)
  end
end
