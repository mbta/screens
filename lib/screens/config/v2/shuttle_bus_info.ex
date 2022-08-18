defmodule Screens.Config.V2.ShuttleBusInfo do
  @moduledoc false

  alias Screens.Config.V2.ShuttleBusSchedule
  alias Screens.V2.WidgetInstance

  @type t :: %__MODULE__{
          minutes_range_to_destination_schedule: list(ShuttleBusSchedule.t()),
          destination: String.t(),
          arrow: arrow(),
          english_boarding_instructions: String.t(),
          spanish_boarding_instructions: String.t(),
          priority: WidgetInstance.priority()
        }

  @type arrow :: :n | :ne | :e | :se | :s | :sw | :w | :nw | nil

  defstruct minutes_range_to_destination_schedule: [],
            destination: nil,
            arrow: nil,
            english_boarding_instructions: nil,
            spanish_boarding_instructions: nil,
            priority: [99]

  use Screens.Config.Struct,
    children: [minutes_range_to_destination_schedule: {:list, ShuttleBusSchedule}],
    with_default: true

  for arrow <- ~w[n ne e se s sw w nw]a do
    arrow_string = Atom.to_string(arrow)
    defp value_from_json("arrow", unquote(arrow_string)), do: unquote(arrow)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
