defmodule Screens.Alerts.Parser do
  @moduledoc false

  def parse_result(result) do
    result
    |> Map.get("data")
    |> parse_data()
  end

  defp parse_data(data) do
    data
    |> Enum.map(fn item -> parse_alert(item) end)
  end

  def parse_alert(%{"id" => id, "attributes" => attributes}) do
    %{"effect" => effect, "header" => header} = attributes

    %Screens.Alerts.Alert{
      id: id,
      effect: effect,
      header: header
    }
  end
end
