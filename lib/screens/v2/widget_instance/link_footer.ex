defmodule Screens.V2.WidgetInstance.LinkFooter do
  @moduledoc false

  alias Screens.V2.WidgetInstance.LinkFooter

  defstruct screen: nil,
            text: nil,
            url: nil

  @type t :: %__MODULE__{
          screen: Screens.Config.Screen.t(),
          text: String.t(),
          url: String.t()
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(%LinkFooter{text: text, url: url}) do
      %{text: text, url: url}
    end

    def slot_names(_instance), do: [:footer]

    def widget_type(_instance), do: :link_footer

    def valid_candidate?(_instance), do: true

    def audio_serialize(_instance), do: %{}

    def audio_sort_key(_instance), do: 0

    def audio_valid_candidate?(_instance), do: false

    def audio_view(_instance), do: ScreensWeb.V2.Audio.LinkFooterView
  end
end
