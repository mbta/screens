defmodule Screens.Config.V2.Audio do
  @moduledoc false

  @type t :: %__MODULE__{
          start_time: Time.t(),
          stop_time: Time.t(),
          daytime_start_time: Time.t(),
          daytime_stop_time: Time.t(),
          days_active: list(Calendar.day_of_week()),
          daytime_volume: float(),
          nighttime_volume: float(),
          interval_offset_seconds: non_neg_integer()
        }

  defstruct start_time: ~T[00:00:00],
            stop_time: ~T[00:00:00],
            daytime_start_time: ~T[00:00:00],
            daytime_stop_time: ~T[00:00:00],
            days_active: [],
            daytime_volume: 0.0,
            nighttime_volume: 0.0,
            interval_offset_seconds: 0

  use Screens.Config.Struct, with_default: true

  for time_key <- ~w[start_time stop_time daytime_start_time daytime_stop_time]a do
    time_key_string = Atom.to_string(time_key)

    defp value_from_json(unquote(time_key_string), iso_string) do
      {:ok, t} = Time.from_iso8601(iso_string)
      t
    end
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
