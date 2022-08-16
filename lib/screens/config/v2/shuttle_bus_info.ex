defmodule Screens.Config.V2.ShuttleBusInfo do
  @moduledoc false

  alias Screens.V2.WidgetInstance

  @type t :: %__MODULE__{
          eta: String.t(),
          destination: String.t(),
          arrow: arrow(),
          priority: WidgetInstance.priority()
        }

  @type arrow :: :n | :ne | :e | :se | :s | :sw | :w | :nw | nil

  @enforce_keys [:eta, :destination, :arrow, :priority]
  defstruct eta: nil,
            destination: nil,
            arrow: nil,
            priority: nil

  use Screens.Config.Struct

  for arrow <- ~w[n ne e se s sw w nw nil]a do
    arrow_string = Atom.to_string(arrow)
    defp value_from_json("arrow", unquote(arrow_string)), do: unquote(arrow)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
