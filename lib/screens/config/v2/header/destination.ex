defmodule Screens.Config.V2.Header.Destination do
  @moduledoc false

  @type t :: %__MODULE__{route_id: String.t(), direction_id: 0 | 1}

  @enforce_keys [:route_id, :direction_id]
  defstruct route_id: nil,
            direction_id: nil

  @spec from_json(map()) :: t()
  def from_json(%{"route_id" => route_id, "direction_id" => direction_id}) do
    %__MODULE__{route_id: route_id, direction_id: direction_id}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{route_id: route_id, direction_id: direction_id}) do
    %{route_id: route_id, direction_id: direction_id}
  end
end
