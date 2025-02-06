defmodule Screens.V2.WidgetInstance.Placeholder do
  @moduledoc false

  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.Placeholder

  defstruct color: nil,
            text: "",
            slot_names: [],
            priority: [100]

  @type color :: :grey | :blue | :green | :red
  @type t :: %__MODULE__{
          color: color(),
          text: String.t(),
          slot_names: list(atom()),
          priority: WidgetInstance.priority()
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(%Placeholder{priority: priority}), do: priority
    def serialize(%Placeholder{color: color, text: text}), do: %{color: color, text: text}
    def slot_names(%Placeholder{slot_names: slot_names}), do: slot_names
    def widget_type(_), do: :placeholder
    def valid_candidate?(_instance), do: true
    @spec audio_serialize(Screens.V2.WidgetInstance.Placeholder.t()) :: %{}
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.PlaceholderView
  end
end
