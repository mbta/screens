defmodule Screens.Config.Gl do
  @moduledoc false

  alias Screens.Config.PsaList
  alias Screens.Util

  @type t :: %__MODULE__{
          stop_id: String.t(),
          platform_id: String.t(),
          route_id: String.t(),
          direction_id: 0 | 1,
          headway_mode: boolean(),
          service_level: pos_integer(),
          psa_list: PsaList.t(),
          nearby_departures: list(String.t())
        }

  @enforce_keys [:stop_id, :platform_id, :route_id, :direction_id]
  defstruct stop_id: nil,
            platform_id: nil,
            route_id: nil,
            direction_id: nil,
            headway_mode: false,
            service_level: 1,
            psa_list: PsaList.from_json(:default),
            nearby_departures: []

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

  defp value_from_json("psa_list", psa_list) do
    PsaList.from_json(psa_list)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(:psa_list, psa_list) do
    PsaList.to_json(psa_list)
  end

  defp value_to_json(_, value), do: value
end
