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
    %{"effect" => effect, "header" => header, "informed_entity" => informed_entities, "updated_at" => updated_at} = attributes

    %Screens.Alerts.Alert{
      id: id,
      effect: effect,
      header: header,
      informed_entities: informed_entities,
      updated_at: parse_time(updated_at)
    }
  end

  defp parse_time(nil), do: nil

  defp parse_time(s) do
    {:ok, time, _} = DateTime.from_iso8601(s)
    time
  end
end
