defmodule Screens.Config.V2.Header.CurrentStopName do
  @moduledoc false

  @type t :: %__MODULE__{stop_name: String.t()}

  @enforce_keys [:stop_name]
  defstruct stop_name: nil

  @spec from_json(map()) :: t()
  def from_json(%{"stop_name" => stop_name}) do
    %__MODULE__{stop_name: stop_name}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{stop_name: stop_name}) do
    %{stop_name: stop_name}
  end
end
