defmodule Screens.Config.Dup.Section.Headway do
  @moduledoc false

  alias Screens.Util

  @typep sign_id :: String.t()
  @typep headway_id :: String.t()
  @typep override :: {pos_integer, pos_integer} | nil

  @type t :: %__MODULE__{
          sign_ids: [sign_id],
          headway_id: headway_id,
          override: override
        }

  defstruct sign_ids: [],
            headway_id: nil,
            override: nil

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    struct_map =
      json
      |> Map.take(Util.struct_keys(__MODULE__))
      |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), value_from_json(k, v)} end)

    struct!(__MODULE__, struct_map)
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(t) do
    t
    |> Map.from_struct()
    |> Enum.into(%{}, fn {k, v} -> {k, value_to_json(k, v)} end)
  end

  defp value_from_json("override", [lo, hi]), do: {lo, hi}
  defp value_from_json(_, value), do: value

  defp value_to_json(:override, {lo, hi}), do: [lo, hi]
  defp value_to_json(_, value), do: value
end
