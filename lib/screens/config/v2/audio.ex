defmodule Screens.Config.V2.Audio do
  @moduledoc false

  @type t :: %__MODULE__{
          start_time: Time.t(),
          stop_time: Time.t(),
          days_active: list(Calendar.day_of_week()),
          volume: float()
        }

  defstruct start_time: ~T[00:00:00],
            stop_time: ~T[00:00:00],
            days_active: [],
            volume: 0.0

  use Screens.Config.Struct, with_default: true

  defp value_from_json("start_time", iso_string) do
    {:ok, t} = Time.from_iso8601(iso_string)
    t
  end

  defp value_from_json("stop_time", iso_string) do
    {:ok, t} = Time.from_iso8601(iso_string)
    t
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
