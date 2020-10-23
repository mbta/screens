defmodule Screens.Config.Dup do
  @moduledoc false

  alias Screens.Config.Dup.{Primary, Secondary}
  alias Screens.Util

  @type t :: %__MODULE__{
    primary: Primary.t(),
    secondary: Secondary.t()
  }

  defstruct primary: Primary.from_json(:default),
            secondary: Secondary.from_json(:default)

  @spec from_json(map()) :: t()
  def from_json(%{} = json) do
    struct_map =
      json
      |> Map.take(Util.struct_keys(__MODULE__))
      |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), value_from_json(k, v)} end)

    struct!(__MODULE__, struct_map)
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = t) do
    t
    |> Map.from_struct()
    |> Enum.into(%{}, fn {k, v} -> {k, value_to_json(k, v)} end)
  end

  defp value_from_json("primary", primary) do
    Primary.from_json(primary)
  end

  defp value_from_json("secondary", secondary) do
    Secondary.from_json(secondary)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(:primary, primary) do
    Primary.to_json(primary)
  end

  defp value_to_json(:secondary, secondary) do
    Secondary.to_json(secondary)
  end

  defp value_to_json(_, value), do: value
end
