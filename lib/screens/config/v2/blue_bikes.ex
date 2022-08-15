defmodule Screens.Config.V2.BlueBikes do
  @moduledoc false

  alias Screens.V2.WidgetInstance

  @type t :: %__MODULE__{
          nearby_dock_ids: list(String.t()),
          destination: String.t() | nil,
          minutes_to_destination: pos_integer() | nil,
          priority: WidgetInstance.priority()
        }

  defstruct nearby_dock_ids: [],
            destination: nil,
            minutes_to_destination: nil,
            priority: [99]

  use Screens.Config.Struct, with_default: true

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
