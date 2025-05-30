defmodule Screens.V2.WidgetInstance.FareInfoFooter do
  @moduledoc false

  alias Screens.V2.WidgetInstance.FareInfoFooter

  defstruct mode: nil, stop_id: nil

  @type t :: %__MODULE__{mode: :bus | :subway, stop_id: String.t() | nil}

  defimpl Screens.V2.WidgetInstance do
    @text "For real-time predictions and fare purchase locations:"

    def priority(_instance), do: [2]

    def serialize(%FareInfoFooter{mode: mode, stop_id: stop_id}) do
      {mode_icon, mode_text, mode_cost} =
        case mode do
          :bus -> {"bus-negative-black.svg", "Local Bus", "$1.70"}
          :subway -> {"subway-negative-black.svg", "Subway", "$2.40"}
        end

      url = if(stop_id, do: "mbta.com/stops/#{stop_id}", else: "mbta.com")

      %{mode_icon: mode_icon, mode_text: mode_text, mode_cost: mode_cost, text: @text, url: url}
    end

    def slot_names(_instance), do: [:footer]

    def widget_type(_instance), do: :fare_info_footer

    def valid_candidate?(_instance), do: true

    def audio_serialize(_instance), do: %{}

    def audio_sort_key(_instance), do: [0]

    def audio_valid_candidate?(_instance), do: false

    def audio_view(_instance), do: ScreensWeb.V2.Audio.FareInfoFooterView
  end
end
