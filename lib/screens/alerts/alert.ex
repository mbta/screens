defmodule Screens.Alerts.Alert do
  @moduledoc false

  defstruct id: nil,
            effect: nil,
            header: nil,
            informed_entities: nil,
            updated_at: nil

  @type t :: %__MODULE__{
          id: String.t(),
          effect: String.t(),
          header: String.t(),
          informed_entities: list(map()),
          updated_at: DateTime.t()
        }

  def to_map(alert) do
    %{
      id: alert.id,
      effect: alert.effect,
      header: alert.header,
      informed_entities: alert.informed_entities,
      updated_at: DateTime.to_iso8601(alert.updated_at)
    }
  end

  def by_stop_id(stop_id) do
    with {:ok, result} <- Screens.V3Api.get_json("alerts", %{"filter[stop]" => stop_id}) do
      Screens.Alerts.Parser.parse_result(result)
    end
  end

  def associate_alerts_with_departures(alerts, departures) do
    Enum.flat_map(alerts, fn alert -> associate_alert_with_departures(alert, departures) end)
  end

  defp associate_alert_with_departures(alert, departures) do
    alert.informed_entities
    |> Enum.flat_map(fn e -> match_departures_by_informed_entity(e, departures) end)
    |> Enum.map(fn departure_id -> [alert.id, departure_id] end)
  end

  # Later, support informed entities other than bus routes
  defp match_departures_by_informed_entity(%{"route" => route_id, "route_type" => 3}, departures) do
    departures
    |> Enum.filter(fn d -> d.route == route_id end)
    |> Enum.map(& &1.id)
  end

  defp match_departures_by_informed_entity(_informed_entity, _departures) do
    []
  end
end
