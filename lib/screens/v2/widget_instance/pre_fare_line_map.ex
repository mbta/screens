defmodule Screens.V2.WidgetInstance.PreFareLineMap do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.V2.WidgetInstance

  defstruct screen: nil,
            asset_url: nil,
            slot_names: nil,
            priority: nil

  @type t :: %__MODULE__{
          screen: Screen.t(),
          asset_url: String.t(),
          slot_names: list(WidgetInstance.slot_id()),
          priority: WidgetInstance.priority()
        }

  def serialize(%__MODULE__{asset_url: asset_url}), do: %{asset_url: asset_url}

  def slot_names(_instance), do: [:main_content_left]

  def priority(_instance), do: [2]

  def widget_type(_instance), do: :pre_fare_line_map

  def valid_candidate?(_instance), do: true

  def audio_serialize(_instance), do: %{}

  def audio_sort_key(_instance), do: 0

  def audio_valid_candidate?(_instance), do: false

  def audio_view(_instance), do: ScreensWeb.V2.Audio.PreFareLineMap

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.PreFareLineMap

    def priority(instance), do: PreFareLineMap.priority(instance)
    def serialize(instance), do: PreFareLineMap.serialize(instance)
    def slot_names(instance), do: PreFareLineMap.slot_names(instance)
    def widget_type(instance), do: PreFareLineMap.widget_type(instance)
    def valid_candidate?(instance), do: PreFareLineMap.valid_candidate?(instance)
    def audio_serialize(instance), do: PreFareLineMap.audio_serialize(instance)
    @spec audio_sort_key(Screens.V2.WidgetInstance.PreFareLineMap.t()) :: 0
    def audio_sort_key(instance), do: PreFareLineMap.audio_sort_key(instance)
    def audio_valid_candidate?(instance), do: PreFareLineMap.audio_valid_candidate?(instance)
    def audio_view(instance), do: PreFareLineMap.audio_view(instance)
  end
end
