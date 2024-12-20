defmodule Screens.V2.WidgetInstance.Elevator.Closure do
  @moduledoc """
  Represents a serializable closure to be displayed on elevator widgets.
  """

  @derive Jason.Encoder

  defstruct ~w[id name]a

  @type t :: %__MODULE__{id: String.t(), name: String.t()}
end
