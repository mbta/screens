defmodule Screens.V2.WidgetInstance.DeparturesNoData do
  @moduledoc false

  @type config :: :ok

  defstruct screen: nil

  @type t :: %__MODULE__{
          screen: config()
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]
    def serialize(_instance), do: %{}
    def slot_names(_instance), do: [:main_content]
  end
end
