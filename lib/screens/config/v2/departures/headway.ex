defmodule Screens.Config.V2.Departures.Headway do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode

  @typep sign_id :: String.t()
  @typep headway_id :: String.t() | nil
  @typep override :: {pos_integer, pos_integer} | nil

  @type t :: %__MODULE__{
          sign_ids: [sign_id],
          headway_id: headway_id,
          override: override
        }

  defstruct sign_ids: [],
            headway_id: nil,
            override: nil

  use Screens.Config.Struct, with_default: true

  defp value_from_json("override", [lo, hi]), do: {lo, hi}
  defp value_from_json(_, value), do: value

  defp value_to_json(:override, {lo, hi}), do: [lo, hi]
  defp value_to_json(_, value), do: value
end
