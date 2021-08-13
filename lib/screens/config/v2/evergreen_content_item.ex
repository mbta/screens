defmodule Screens.Config.V2.EvergreenContentItem do
  @moduledoc false

  alias Screens.V2.WidgetInstance

  @type t :: %__MODULE__{
          slot_names: list(WidgetInstance.slot_id()),
          asset_path: String.t(),
          priority: WidgetInstance.priority()
        }

  @enforce_keys ~w[slot_names asset_path priority]a
  defstruct @enforce_keys

  use Screens.Config.Struct

  defp value_from_json("slot_names", slot_names) do
    Enum.map(slot_names, &String.to_existing_atom/1)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
