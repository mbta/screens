defmodule Screens.Schedules.Parser do
  @moduledoc false

  def parse_result(%{"data" => data}) do
    Enum.map(data, &parse_schedule/1)
  end

  defp parse_schedule(%{"id" => id, "attributes" => %{"departure_time" => departure_time_string}}) do
    departure_time = parse_time(departure_time_string)
    %Screens.Schedules.Schedule{id: id, time: departure_time}
  end

  defp parse_time(nil), do: nil

  defp parse_time(s) do
    {:ok, time, _} = DateTime.from_iso8601(s)
    time
  end
end
