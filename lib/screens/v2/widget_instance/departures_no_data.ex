defmodule Screens.V2.WidgetInstance.DeparturesNoData do
  @moduledoc false

  defstruct screen: nil

  @type t :: %__MODULE__{
          screen: Screens.Config.Screen.t()
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]
    def serialize(_instance), do: %{}
    def slot_names(_instance), do: [:main_content]
    def widget_type(_instance), do: :departures_no_data
  end
end
