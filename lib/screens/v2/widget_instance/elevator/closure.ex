defmodule Screens.V2.WidgetInstance.Elevator.Closure do
  @moduledoc """
  Represents a serializable closure to be displayed on elevator widgets.
  """

  @derive Jason.Encoder

  defstruct ~w[id elevator_name elevator_id description header_text]a

  @type t :: %__MODULE__{
          id: String.t(),
          elevator_name: String.t(),
          elevator_id: String.t(),
          description: String.t(),
          header_text: String.t()
        }
end
