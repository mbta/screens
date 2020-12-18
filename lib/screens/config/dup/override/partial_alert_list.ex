defmodule Screens.Config.Dup.Override.PartialAlertList do
  @moduledoc false

  alias Screens.Config.Dup.Override.PartialAlert

  @type t :: %__MODULE__{alerts: list(PartialAlert.t())}

  @enforce_keys [:alerts]
  defstruct @enforce_keys

  def from_json(%{"alerts" => alerts}) do
    %__MODULE__{alerts: Enum.map(alerts, &PartialAlert.from_json/1)}
  end

  def to_json(%__MODULE__{alerts: alerts}) do
    %{
      type: :partial,
      alerts: Enum.map(alerts, &PartialAlert.to_json/1)
    }
  end
end
