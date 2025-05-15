defmodule Screens.V2.WidgetInstance.AudioOnly.ContentSummary do
  @moduledoc """
  An audio-only widget that summarizes what's about to be read out.
  """

  alias Screens.Report
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.{NormalHeader, ShuttleBusInfo}
  alias ScreensConfig
  alias ScreensConfig.{Header, Screen}
  alias ScreensConfig.Screen.PreFare

  @type subway_line :: :red | :orange | :green | :blue

  @type t :: %__MODULE__{
          screen: Screen.t(),
          widgets_snapshot: list(WidgetInstance.t()),
          lines_at_station: list(subway_line())
        }

  @enforce_keys [:screen, :widgets_snapshot, :lines_at_station]
  defstruct @enforce_keys

  # This value is appended to the target widget in order to insert this one
  # immediately after the target, and is unique among other audio-only widgets'
  # sort keys so that there is a definite ordering should two audio-only widgets
  # end up adjacent to each other.
  @audio_sort_key_part [0]

  def audio_serialize(
        %__MODULE__{
          screen: %Screen{
            app_id: :pre_fare_v2,
            app_params: %PreFare{departures: %ScreensConfig.Departures{sections: [_ | _]}}
          }
        } = t
      ) do
    %{
      lines_at_station: t.lines_at_station,
      has_departures: true
    }
  end

  def audio_serialize(%__MODULE__{screen: %Screen{app_id: :pre_fare_v2}} = t) do
    %{lines_at_station: t.lines_at_station, has_departures: false}
  end

  def audio_sort_key(%__MODULE__{} = t) do
    # Attempt to find a header widget and place this widget immediately after it
    case Enum.find(t.widgets_snapshot, &match?(%NormalHeader{}, &1)) do
      nil ->
        Report.warning("content_summary_header_not_found")
        [0]

      header ->
        WidgetInstance.audio_sort_key(header) ++ @audio_sort_key_part
    end
  end

  def audio_valid_candidate?(%__MODULE__{
        screen: %Screen{
          app_id: :pre_fare_v2,
          app_params: %PreFare{header: %Header.StopId{stop_id: stop_id}}
        },
        widgets_snapshot: widgets
      }) do
    # Need to skip this readout for Wellington during the OL Surge
    not (has_surge_widgets?(widgets) and stop_id in ["place-welln"])
  end

  def audio_valid_candidate?(_t) do
    false
  end

  def audio_view(%__MODULE__{widgets_snapshot: widgets}) do
    if has_surge_widgets?(widgets) do
      ScreensWeb.V2.Audio.SurgeContentSummaryView
    else
      ScreensWeb.V2.Audio.ContentSummaryView
    end
  end

  defp has_surge_widgets?(widgets) do
    Enum.any?(widgets, &match?(%ShuttleBusInfo{}, &1))
  end

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.AudioOnly.ContentSummary

    # Since this is an audio-only widget, these functions will never be called.
    def priority(_instance), do: :no_render
    def serialize(_instance), do: %{}
    def slot_names(_instance), do: :no_render
    def widget_type(_instance), do: :no_render
    def valid_candidate?(_instance), do: false

    def audio_serialize(instance), do: ContentSummary.audio_serialize(instance)
    def audio_sort_key(instance), do: ContentSummary.audio_sort_key(instance)
    def audio_valid_candidate?(instance), do: ContentSummary.audio_valid_candidate?(instance)
    def audio_view(instance), do: ContentSummary.audio_view(instance)
  end
end
