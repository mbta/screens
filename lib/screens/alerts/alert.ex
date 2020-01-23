defmodule Screens.Alerts.Alert do
  @moduledoc false

  defstruct id: nil,
            effect: nil,
            header: nil

  @type t :: %__MODULE__{
          id: String.t(),
          effect: String.t(),
          header: String.t()
        }

  def to_map(alert) do
    %{
      id: alert.id,
      effect: alert.effect,
      header: alert.header
    }
  end

  def by_stop_id(stop_id) do
    with {:ok, result} <- Screens.V3Api.get_json("alerts", %{"filter[stop]" => stop_id}) do
      Screens.Alerts.Parser.parse_result(result)
    end
  end
end
