defmodule Screens.V2.WidgetInstance.FareInfoFooter do
  @moduledoc false

  alias Screens.V2.WidgetInstance.FareInfoFooter

  defstruct screen: nil,
            mode: nil,
            text: nil,
            url: nil

  @type mode :: :bus | :subway
  @type t :: %__MODULE__{
          screen: Screens.Config.Screen.t(),
          mode: mode,
          text: String.t(),
          url: String.t()
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(%FareInfoFooter{mode: mode, text: text, url: url}) do
      {mode_icon, mode_text, mode_cost} =
        case mode do
          :bus -> {"bus-negative-black.svg", "Local Bus", "$1.70"}
          :subway -> {"subway-negative-black.svg", "Subway", "$2.40"}
        end

      %{mode_icon: mode_icon, mode_text: mode_text, mode_cost: mode_cost, text: text, url: url}
    end

    def slot_names(_instance), do: [:footer]

    def widget_type(_instance), do: :fare_info_footer

    def valid_candidate?(_instance), do: true

    def audio_serialize(_instance), do: ""

    def audio_sort_key(_instance), do: 0

    def audio_valid_candidate?(_instance), do: false
  end
end
