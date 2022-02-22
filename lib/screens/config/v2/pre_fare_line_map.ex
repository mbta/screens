defmodule Screens.Config.V2.PreFareLineMap do
  @moduledoc false

  @type t :: %__MODULE__{
          asset_path: String.t(),
          slot_names: list(WidgetInstance.slot_id())
        }

  @enforce_keys [:asset_path, :slot_names]
  defstruct asset_path: nil,
            slot_names: nil

  use Screens.Config.Struct

  defp value_from_json("slot_names", slot_names) do
    Enum.map(slot_names, &String.to_existing_atom/1)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
