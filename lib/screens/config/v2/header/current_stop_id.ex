defmodule Screens.Config.V2.Header.CurrentStopId do
  @moduledoc false

  @type t :: %__MODULE__{stop_id: String.t()}

  @enforce_keys [:stop_id]
  defstruct stop_id: nil

  @spec from_json(map()) :: t()
  def from_json(%{"stop_id" => stop_id}) do
    %__MODULE__{stop_id: stop_id}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{stop_id: stop_id}) do
    %{stop_id: stop_id}
  end
end
