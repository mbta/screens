defmodule Screens.Config.V2.EvergreenContentInstance do
  @moduledoc false

  alias Screens.V2.WidgetInstance

  @type t :: %__MODULE__{
          slot_name: WidgetInstance.slot_id(),
          asset_path: String.t(),
          priority: WidgetInstance.priority()
        }

  @enforce_keys ~w[slot_name asset_path priority]a
  defstruct @enforce_keys

  use Screens.Config.Struct

  defp value_from_json("slot_name", slot_name) do
    String.to_existing_atom(slot_name)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
