defmodule Screens.V2.WidgetInstance.MockWidget do
  @moduledoc "A mock widget instance to be used in tests"

  @enforce_keys [:slot_names]
  defstruct priority: [2],
            widget_type: :mock_widget,
            content: nil,
            slot_names: nil,
            valid_candidate?: true

  @type t :: %__MODULE__{
          priority: list(non_neg_integer()),
          widget_type: atom(),
          content: any(),
          slot_names: list(atom()),
          valid_candidate?: boolean()
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(t), do: t.priority
    def serialize(t), do: %{content: t.content}
    def slot_names(t), do: t.slot_names
    def widget_type(t), do: t.widget_type
    def valid_candidate?(t), do: t.valid_candidate?
  end
end
