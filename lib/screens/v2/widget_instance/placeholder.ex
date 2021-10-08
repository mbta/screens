defmodule Screens.V2.WidgetInstance.Placeholder do
  @moduledoc false

  alias Screens.V2.WidgetInstance.Placeholder

  defstruct color: nil,
            slot_names: []

  @type color :: :grey | :blue | :green | :red
  @type t :: %__MODULE__{
          color: color(),
          slot_names: list(atom())
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(_), do: [100]
    def serialize(%Placeholder{color: color}), do: %{color: color}
    def slot_names(%Placeholder{slot_names: slot_names}), do: slot_names
    def widget_type(_), do: :placeholder
    def valid_candidate?(_instance), do: true
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: 0
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.Views.V2.Audio.PlaceholderView
  end
end
