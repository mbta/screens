defmodule Screens.V2.WidgetInstance.BottomScreenFiller do
  @moduledoc """
  A low-priority widget used to fill the bottom screen of E-Ink double stacks
  when the top screen is taken over by content that should prevent normal
  service info from showing.

  Because of its low priority and ability to fit into only the
  `full_body_bottom_screen` slot, this widget will be discarded from the running
  unless another higher priority widget forces the framework to choose the
  `body_takeover` or `bottom_takeover` layout variant of the e-ink template's
  `body` region.
  """

  alias ScreensConfig.Screen

  defstruct ~w[screen]a

  @type t :: %__MODULE__{screen: Screen.t()}

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [10]
    def serialize(_instance), do: %{}
    def slot_names(_instance), do: [:full_body_bottom_screen]
    def widget_type(_instance), do: :bottom_screen_filler
    def valid_candidate?(_instance), do: true

    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.NullView
  end
end
