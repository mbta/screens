defmodule Screens.Config.DateTimeRange do
  @moduledoc false

  @type t :: {start_time :: DateTime.t(), end_time :: DateTime.t()}

  @spec from_json(map()) :: t()
  def from_json(%{"start_time" => start_time_string, "end_time" => end_time_string}) do
    {:ok, start_time, _offset} = DateTime.from_iso8601(start_time_string)
    {:ok, end_time, _offset} = DateTime.from_iso8601(end_time_string)

    {start_time, end_time}
  end

  @spec to_json(t()) :: map()
  def to_json({start_time, end_time}) do
    %{
      start_time: DateTime.to_iso8601(start_time),
      end_time: DateTime.to_iso8601(end_time)
    }
  end
end
