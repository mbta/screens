defmodule Screens.Config.V2.ShuttleBusInfo do
  @moduledoc false

  alias Screens.V2.WidgetInstance

  @type t :: %__MODULE__{
          minutes_range_to_destination: String.t(),
          destination: String.t(),
          arrow: arrow(),
          english_boarding_instructions: String.t(),
          spanish_boarding_instructions: String.t(),
          priority: WidgetInstance.priority()
        }

  @type arrow :: :n | :ne | :e | :se | :s | :sw | :w | :nw | nil

  @enforce_keys [
    :minutes_range_to_destination,
    :destination,
    :arrow,
    :english_boarding_instructions,
    :spanish_boarding_instructions,
    :priority
  ]
  defstruct @enforce_keys

  use Screens.Config.Struct

  for arrow <- ~w[n ne e se s sw w nw nil]a do
    arrow_string = Atom.to_string(arrow)
    defp value_from_json("arrow", unquote(arrow_string)), do: unquote(arrow)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
