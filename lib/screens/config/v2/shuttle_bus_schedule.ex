defmodule Screens.Config.V2.ShuttleBusSchedule do
  @moduledoc false

  @type t :: %__MODULE__{
          start_time: Time.t(),
          end_time: Time.t(),
          days: :weekday | :saturday | :sunday,
          minute_range: String.t()
        }

  defstruct start_time: ~T[00:00:00],
            end_time: ~T[00:00:00],
            days: nil,
            minute_range: nil

  use Screens.Config.Struct

  for time_key <- ~w[start_time end_time]a do
    time_key_string = Atom.to_string(time_key)

    defp value_from_json(unquote(time_key_string), iso_string) do
      {:ok, t} = Time.from_iso8601(iso_string)
      t
    end
  end

  defp value_from_json("days", days) do
    days |> String.downcase() |> String.to_existing_atom()
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
