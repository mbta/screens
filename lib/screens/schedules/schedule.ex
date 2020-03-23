defmodule Screens.Schedules.Schedule do
  @moduledoc false

  defstruct id: nil,
            time: nil

  @type t :: %__MODULE__{
          id: String.t(),
          time: DateTime.t()
        }

  def by_stop_id(stop_id, route_id) do
    case Screens.V3Api.get_json("schedules", %{
           "filter[stop]" => stop_id,
           "filter[route]" => route_id,
           "sort" => "departure_time"
         }) do
      {:ok, result} -> {:ok, Screens.Schedules.Parser.parse_result(result)}
      _ -> :error
    end
  end

  def next_departure(stop_id, route_id, time \\ DateTime.add(DateTime.utc_now(), -180)) do
    case by_stop_id(stop_id, route_id) do
      {:ok, [_ | _] = schedules} ->
        case Enum.filter(schedules, &check_after(&1, time)) do
          [first | _] -> {:ok, first}
          [] -> :error
        end

      _ ->
        :error
    end
  end

  defp check_after(%{time: nil}, _time) do
    false
  end

  defp check_after(%{time: t}, time) do
    DateTime.compare(t, time) == :gt
  end
end
