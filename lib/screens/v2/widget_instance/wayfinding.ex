defmodule Screens.V2.WidgetInstance.Wayfinding do
  @moduledoc false

  alias ScreensConfig.Screen

  @enforce_keys ~w[screen asset_url header_text text_for_audio slot_names]a
  defstruct screen: nil,
            asset_url: nil,
            header_text: nil,
            text_for_audio: nil,
            slot_names: nil

  @type t :: %__MODULE__{
          screen: Screen.t(),
          asset_url: String.t(),
          header_text: String.t() | nil,
          text_for_audio: String.t() | nil,
          slot_names: list(atom())
        }

  def serialize(%__MODULE__{asset_url: asset_url, header_text: header_text}),
    do: %{asset_url: asset_url, header_text: header_text}

  def slot_names(%__MODULE__{slot_names: slot_names}), do: slot_names

  def valid_candidate?(%__MODULE__{asset_url: asset_url}) when asset_url != nil, do: true

  def valid_candidate?(_), do: false

  def audio_serialize(%__MODULE__{text_for_audio: text_for_audio}),
    do: %{text: text_for_audio}

  def audio_valid_candidate?(%__MODULE__{text_for_audio: text_for_audio})
      when not is_nil(text_for_audio),
      do: true

  def audio_valid_candidate?(_), do: false

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.Wayfinding

    def priority(_instance), do: [3]
    def serialize(instance), do: Wayfinding.serialize(instance)
    def slot_names(instance), do: Wayfinding.slot_names(instance)
    def page_groups(_instance), do: []
    def widget_type(_instance), do: :wayfinding
    def valid_candidate?(instance), do: Wayfinding.valid_candidate?(instance)
    def audio_serialize(instance), do: Wayfinding.audio_serialize(instance)
    def audio_sort_key(_instance), do: [2]

    def audio_valid_candidate?(instance),
      do: Wayfinding.audio_valid_candidate?(instance)

    def audio_view(_instance), do: ScreensWeb.V2.Audio.WayfindingView
  end
end
