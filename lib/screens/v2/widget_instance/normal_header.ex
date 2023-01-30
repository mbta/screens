defmodule Screens.V2.WidgetInstance.NormalHeader do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.Header.Destination
  alias Screens.V2.WidgetInstance.NormalHeader

  defstruct screen: nil,
            icon: nil,
            text: nil,
            time: nil

  @type icon :: :logo | :green_b | :green_c | :green_d | :green_e
  @type t :: %__MODULE__{
          screen: Screens.Config.Screen.t(),
          icon: icon | nil,
          text: String.t(),
          time: DateTime.t()
        }

  def serialize(%__MODULE__{icon: icon, text: text, time: time} = t) do
    %{icon: icon, text: text, time: DateTime.to_iso8601(time), show_to: showing_destination?(t)}
  end

  def slot_names(%__MODULE__{screen: %Screen{app_id: :dup_v2}}) do
    [:header_zero, :header_one, :header_two]
  end

  def slot_names(%__MODULE__{}) do
    [:header]
  end

  defp showing_destination?(%__MODULE__{
         screen: %Screen{app_params: %_app{header: %Destination{}}}
       }) do
    true
  end

  defp showing_destination?(%__MODULE__{}) do
    false
  end

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(t), do: NormalHeader.serialize(t)

    def slot_names(t), do: NormalHeader.slot_names(t)

    def widget_type(_instance), do: :normal_header

    def valid_candidate?(_instance), do: true

    def audio_serialize(%NormalHeader{text: text}), do: %{text: text}

    def audio_sort_key(_instance), do: [0]

    def audio_valid_candidate?(_instance), do: true

    def audio_view(_instance), do: ScreensWeb.V2.Audio.NormalHeaderView
  end
end
