defmodule Screens.V2.WidgetInstance.MockWidget do
  @moduledoc "A mock widget instance to be used in tests"

  @enforce_keys [:slot_names]
  defstruct priority: [2],
            widget_type: :mock_widget,
            content: nil,
            slot_names: nil,
            valid_candidate?: true,
            audio_sort_key: 0,
            audio_valid_candidate?: false

  @type t :: %__MODULE__{
          priority: list(non_neg_integer()),
          widget_type: atom(),
          content: any(),
          slot_names: list(atom()),
          valid_candidate?: boolean(),
          audio_sort_key: non_neg_integer(),
          audio_valid_candidate?: boolean()
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(t), do: t.priority
    def serialize(t), do: %{content: t.content}
    def slot_names(t), do: t.slot_names
    def widget_type(t), do: t.widget_type
    def valid_candidate?(t), do: t.valid_candidate?
    def audio_serialize(t), do: t.audio_serialize
    def audio_sort_key(t), do: t.audio_sort_key
    def audio_valid_candidate?(t), do: t.audio_valid_candidate?
  end
end
