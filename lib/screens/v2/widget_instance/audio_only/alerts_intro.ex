defmodule Screens.V2.WidgetInstance.AudioOnly.AlertsIntro do
  @moduledoc """
  An audio-only widget that introduces the section of the readout describing service alerts.
  """

  alias Screens.Report
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.{ReconstructedAlert, SubwayStatus}
  alias ScreensConfig.Screen

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
  @audio_sort_key_part [1]

  def audio_serialize(%__MODULE__{screen: %Screen{app_id: :pre_fare_v2}}) do
    %{}
  end

  def audio_sort_key(%__MODULE__{} = t, audio_sort_key_fn \\ &WidgetInstance.audio_sort_key/1) do
    # After sorting, attempt to find the first subway status or alert widget,
    # and insert this widget immediately before it.
    # (Technically, immediately after the preceding widget)

    sorted_widgets = Enum.sort_by(t.widgets_snapshot, audio_sort_key_fn)

    first_service_alert_index = Enum.find_index(sorted_widgets, &service_alert_widget?/1)

    case first_service_alert_index do
      nil ->
        Report.warning("alerts_intro_widget_not_found")
        [0]

      0 ->
        Report.warning("alerts_intro_widget_at_queue_start")
        [0]

      i ->
        preceding_widget_sort_key =
          sorted_widgets
          |> Enum.at(i - 1)
          |> audio_sort_key_fn.()

        preceding_widget_sort_key ++ @audio_sort_key_part
    end
  end

  def audio_valid_candidate?(%__MODULE__{
        screen: %Screen{app_id: :pre_fare_v2},
        widgets_snapshot: widgets
      }) do
    Enum.any?(widgets, &service_alert_widget?/1)
  end

  def audio_valid_candidate?(_t), do: false

  def audio_view(_instance), do: ScreensWeb.V2.Audio.AlertsIntroView

  defp service_alert_widget?(%ReconstructedAlert{}), do: true
  defp service_alert_widget?(%SubwayStatus{}), do: true
  defp service_alert_widget?(%_other_widget_instance{}), do: false

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.AudioOnly.AlertsIntro

    # Since this is an audio-only widget, these functions will never be called.
    def priority(_instance), do: :no_render
    def serialize(_instance), do: %{}
    def slot_names(_instance), do: :no_render
    def widget_type(_instance), do: :no_render
    def valid_candidate?(_instance), do: false

    def audio_serialize(instance), do: AlertsIntro.audio_serialize(instance)
    def audio_sort_key(instance), do: AlertsIntro.audio_sort_key(instance)
    def audio_valid_candidate?(instance), do: AlertsIntro.audio_valid_candidate?(instance)
    def audio_view(instance), do: AlertsIntro.audio_view(instance)
  end
end
