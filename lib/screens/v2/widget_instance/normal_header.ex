defmodule Screens.V2.WidgetInstance.NormalHeader do
  @moduledoc false

  alias Screens.V2.WidgetInstance.NormalHeader
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Header.Destination

  defstruct screen: nil,
            icon: nil,
            text: nil,
            time: nil,
            variant: nil

  @type icon :: :logo | :green_b | :green_c | :green_d | :green_e
  @type t :: %__MODULE__{
          screen: ScreensConfig.Screen.t(),
          icon: icon | nil,
          text: String.t(),
          time: DateTime.t(),
          variant: atom() | nil
        }

  # Mercury adds their own time so we omit the time in the response.
  # https://app.asana.com/0/1185117109217413/1206070378353406/f
  def serialize(%__MODULE__{screen: %Screen{vendor: :mercury}, icon: icon, text: text} = t) do
    %{icon: icon, text: text, show_to: showing_destination?(t)}
  end

  def serialize(%__MODULE__{icon: icon, text: text, time: time, variant: variant} = t) do
    %{
      icon: icon,
      text: text,
      time: DateTime.to_iso8601(time),
      show_to: showing_destination?(t),
      variant: variant
    }
  end

  def slot_names(%__MODULE__{screen: %Screen{app_id: :dup_v2}}) do
    [:header_zero, :header_one, :header_two]
  end

  def slot_names(%__MODULE__{}) do
    [:header]
  end

  def audio_serialize(%__MODULE__{screen: %Screen{app_id: :gl_eink_v2}, text: text, icon: icon})
      when icon in [:green_b, :green_c, :green_d, :green_e] do
    "green_" <> branch = to_string(icon)
    %{text: text, branch: branch}
  end

  def audio_serialize(%__MODULE__{text: text}), do: %{text: text}

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

    def audio_serialize(instance), do: NormalHeader.audio_serialize(instance)

    def audio_sort_key(_instance), do: [0]

    def audio_valid_candidate?(_instance), do: true

    def audio_view(_instance), do: ScreensWeb.V2.Audio.NormalHeaderView
  end
end
