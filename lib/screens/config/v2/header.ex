defmodule Screens.Config.V2.Header do
  @moduledoc false

  @typep current_stop_id_type :: %__MODULE__{type: :current_stop_id, stop_id: String.t()}
  @typep current_stop_name_type :: %__MODULE__{type: :current_stop_name, stop_name: String.t()}
  @typep destination_type :: %__MODULE__{
           type: :destination,
           route_id: String.t(),
           direction_id: 0 | 1
         }
  @type t :: current_stop_id_type | current_stop_name_type | destination_type

  @enforce_keys [:type]
  defstruct type: nil,
            stop_id: nil,
            stop_name: nil,
            route_id: nil,
            direction_id: nil

  @spec from_json(map()) :: t()
  def from_json(%{"type" => "current_stop_id", "stop_id" => stop_id}) do
    %__MODULE__{type: :current_stop_id, stop_id: stop_id}
  end

  def from_json(%{"type" => "current_stop_name", "stop_name" => stop_name}) do
    %__MODULE__{type: :current_stop_name, stop_name: stop_name}
  end

  def from_json(%{"type" => "destination", "route_id" => route_id, "direction_id" => direction_id}) do
    %__MODULE__{
      type: :destination,
      route_id: route_id,
      direction_id: direction_id
    }
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{type: :current_stop_id, stop_id: stop_id}) do
    %{type: :current_stop_id, stop_id: stop_id}
  end

  def to_json(%__MODULE__{type: :current_stop_name, stop_name: stop_name}) do
    %{type: :current_stop_name, stop_name: stop_name}
  end

  def to_json(%__MODULE__{type: :destination, route_id: route_id, direction_id: direction_id}) do
    %{type: :destination, route_id: route_id, direction_id: direction_id}
  end
end
