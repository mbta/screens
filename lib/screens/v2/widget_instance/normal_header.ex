defmodule Screens.V2.WidgetInstance.NormalHeader do
  @moduledoc false

  alias Screens.V2.WidgetInstance.NormalHeader

  defstruct screen: nil,
            icon: nil,
            text: nil,
            time: nil

  @type icon :: :logo | :x | :green_b | :green_c | :green_d | :green_e
  @type t :: %__MODULE__{
          screen: Screens.Config.Screen.t(),
          icon: icon | nil,
          text: String.t(),
          time: DateTime.t()
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(%NormalHeader{icon: icon, text: text, time: time}) do
      %{icon: icon, text: text, time: DateTime.to_iso8601(time)}
    end

    def slot_names(_instance), do: [:header]

    def widget_type(_instance), do: :normal_header

    def valid_candidate?(_instance), do: true

    def audio_serialize(_instance), do: ""

    def audio_sort_key(_instance), do: 0

    def audio_valid_candidate?(_instance), do: false
  end
end
