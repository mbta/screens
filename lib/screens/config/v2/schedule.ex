defmodule Screens.Config.V2.Schedule do
  @moduledoc false

  @type t :: %__MODULE__{
          start_dt: DateTime.t() | nil,
          end_dt: DateTime.t() | nil
        }

  defstruct start_dt: nil,
            end_dt: nil

  use Screens.Config.Struct

  defp value_from_json(_, nil), do: nil

  defp value_from_json("start_dt", iso_string) do
    {:ok, dt, _offset} = DateTime.from_iso8601(iso_string)
    dt
  end

  defp value_from_json("end_dt", iso_string) do
    {:ok, dt, _offset} = DateTime.from_iso8601(iso_string)
    dt
  end

  defp value_to_json(_, nil), do: nil

  defp value_to_json(_, datetime) do
    DateTime.to_iso8601(datetime)
  end
end
