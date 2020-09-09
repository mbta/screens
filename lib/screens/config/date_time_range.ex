defmodule Screens.Config.DateTimeRange do
  @moduledoc false

  @type t :: {start_time :: nillable_datetime(), end_time :: nillable_datetime()}

  @typep nillable_datetime :: DateTime.t() | nil

  @spec from_json(map()) :: t()
  def from_json(%{"start_time" => start_time, "end_time" => end_time}) do
    start_time = nillable_datetime_from_json(start_time)
    end_time = nillable_datetime_from_json(end_time)

    {start_time, end_time}
  end

  @spec to_json(t()) :: map()
  def to_json({start_time, end_time}) do
    %{
      start_time: nillable_datetime_to_json(start_time),
      end_time: nillable_datetime_to_json(end_time)
    }
  end

  defp nillable_datetime_from_json(nil), do: nil
  defp nillable_datetime_from_json(dt_string) do
    {:ok, dt, _offset} = DateTime.from_iso8601(dt_string)
    dt
  end

  defp nillable_datetime_to_json(nil), do: nil
  defp nillable_datetime_to_json(dt) do
    DateTime.to_iso8601(dt)
  end
end
