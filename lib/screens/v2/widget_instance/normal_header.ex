defmodule Screens.V2.WidgetInstance.NormalHeader do
  @moduledoc false

  alias Screens.V2.WidgetInstance.NormalHeader
  alias ScreensConfig.Header.Destination
  alias ScreensConfig.Screen

  defstruct screen: nil,
            icon: nil,
            read_as: nil,
            text: nil,
            time: nil,
            variant: nil

  @type icon :: :logo | :green_b | :green_c | :green_d | :green_e
  @type t :: %__MODULE__{
          screen: ScreensConfig.Screen.t(),
          icon: icon | nil,
          read_as: String.t() | nil,
          text: String.t(),
          time: DateTime.t(),
          variant: atom() | nil
        }

  # See `docs/mercury_api.md`
  def serialize(
        %__MODULE__{screen: %Screen{vendor: :mercury}, icon: icon, text: text, read_as: read_as} =
          t
      ) do
    %{icon: icon, text: text, show_to: showing_destination?(t), read_as: read_as}
  end

  def serialize(
        %__MODULE__{icon: icon, text: text, time: time, variant: variant, read_as: read_as} = t
      ) do
    %{
      icon: icon,
      read_as: read_as,
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

  def audio_serialize(%__MODULE__{
        screen: %Screen{app_id: :gl_eink_v2},
        read_as: read_as,
        icon: icon
      })
      when icon in [:green_b, :green_c, :green_d, :green_e] do
    "green_" <> branch = to_string(icon)
    %{read_as: read_as, branch: branch}
  end

  def audio_serialize(%__MODULE__{read_as: read_as}), do: %{read_as: read_as}

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
