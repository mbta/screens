defmodule Screens.V2.WidgetInstance.LinkFooter do
  @moduledoc false

  alias Screens.V2.WidgetInstance.LinkFooter

  @enforce_keys [:text]
  defstruct @enforce_keys ++ [stop_id: nil]

  @type t :: %__MODULE__{stop_id: String.t() | nil, text: String.t()}

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(%LinkFooter{stop_id: stop_id, text: text}) do
      %{text: text, url: if(stop_id, do: "mbta.com/stops/#{stop_id}", else: "mbta.com")}
    end

    def slot_names(_instance), do: [:footer]

    def widget_type(_instance), do: :link_footer

    def valid_candidate?(_instance), do: true

    def audio_serialize(_instance), do: %{}

    def audio_sort_key(_instance), do: [0]

    def audio_valid_candidate?(_instance), do: false

    def audio_view(_instance), do: ScreensWeb.V2.Audio.LinkFooterView
  end
end
