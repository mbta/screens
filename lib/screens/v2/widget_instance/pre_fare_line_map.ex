defmodule Screens.V2.WidgetInstance.PreFareLineMap do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.V2.WidgetInstance.PreFareLineMap
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

  def slot_names(%__MODULE__{slot_names: slot_names}), do: slot_names

  defimpl Screens.V2.WidgetInstance do
    def priority(%PreFareLineMap{priority: priority}), do: priority
    def serialize(instance), do: serialize(instance)
    def slot_names(instance), do: slot_names(instance)
    def widget_type(_), do: :pre_fare_line_map
    def valid_candidate?(_instance), do: true
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: 0
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.PreFareLineMap
  end
end
