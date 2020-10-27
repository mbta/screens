defmodule Screens.Config.Dup.Secondary do
  @moduledoc false

  alias Screens.Config.Dup.Primary
  alias Screens.Util

  @type t :: %__MODULE__{
          good_state: Primary.t()
          # TODO more fields TBD to configure alerting
        }

  defstruct good_state: Primary.from_json(:default)

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
  def to_json(%__MODULE__{} = t) do
    t
    |> Map.from_struct()
    |> Enum.into(%{}, fn {k, v} -> {k, value_to_json(k, v)} end)
  end

  defp value_from_json("good_state", good_state_config) do
    Primary.from_json(good_state_config)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
