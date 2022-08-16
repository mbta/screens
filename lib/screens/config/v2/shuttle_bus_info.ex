defmodule Screens.Config.V2.ShuttleBusInfo do
  @moduledoc false

  alias Screens.V2.WidgetInstance

  @type t :: %__MODULE__{
          eta: String.t(),
          destination: String.t(),
          direction: String.t(),
          priority: WidgetInstance.priority()
        }

  @enforce_keys [:eta, :destination, :direction, :priority]
  defstruct eta: nil,
            destination: nil,
            direction: nil,
            priority: nil

  use Screens.Config.Struct

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
