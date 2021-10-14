defmodule Screens.Config.V2.Audio do
  @moduledoc false

  @type t :: %__MODULE__{
          start_time: Time.t(),
          stop_time: Time.t(),
          days_active: list(Calendar.day_of_week()),
          volume: float()
        }

  @enforce_keys [:start_time, :stop_time, :days_active, :volume]
  defstruct @enforce_keys

  use Screens.Config.Struct

  defp value_from_json(_, value), do: value
  defp value_to_json(_, value), do: value
end
