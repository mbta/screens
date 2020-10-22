defmodule Screens.Config.Solari.Section.Headway do
  @moduledoc false

  alias Screens.Util

  @typep sign_id :: String.t()
  @typep headway_id :: String.t()
  @typep headsign :: String.t()

  @type t :: %__MODULE__{
          sign_ids: [sign_id],
          headway_id: headway_id,
          headsigns: [headsign]
        }

  defstruct sign_ids: [],
            headway_id: nil,
            headsigns: []

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    struct_map =
      json
      |> Map.take(Util.struct_keys(__MODULE__))
      |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), v} end)

    struct!(__MODULE__, struct_map)
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(t) do
    Map.from_struct(t)
  end
end
