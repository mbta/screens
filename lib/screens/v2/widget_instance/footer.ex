defmodule Screens.V2.WidgetInstance.Footer do
  @moduledoc false

  alias ScreensConfig.Screen

  defstruct screen: nil

  @type t :: %__MODULE__{
          screen: Screen.t()
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [1]

    def serialize(_instance), do: %{}

    def slot_names(_instance), do: [:footer]

    def widget_type(_instance), do: :footer

    def valid_candidate?(_instance), do: true

    def audio_serialize(_instance), do: %{}

    def audio_sort_key(_instance), do: [0]

    def audio_valid_candidate?(_instance), do: false

    def audio_view(_instance), do: ScreensWeb.V2.Audio.FooterView
  end
end