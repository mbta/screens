defmodule Screens.Config.PsaConfig.OverrideList do
  @moduledoc false

  alias Screens.Config.{DateTimeRange, PsaConfig.PsaList}
  alias Screens.Util

  @type t :: %__MODULE__{
          psa_list: PsaList.t(),
          active_time_range: DateTimeRange.t()
        }

  @enforce_keys [:psa_list, :active_time_range]
  defstruct @enforce_keys

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

  defp value_from_json("active_time_range", active_time_range) do
    DateTimeRange.from_json(active_time_range)
  end

  defp value_from_json("psa_list", psa_list) do
    PsaList.from_json(psa_list)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(:active_time_range, active_time_range) do
    DateTimeRange.to_json(active_time_range)
  end

  defp value_to_json(:psa_list, psa_list) do
    PsaList.to_json(psa_list)
  end

  defp value_to_json(_, value), do: value
end
