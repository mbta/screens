defmodule Screens.V2.ScreenData.Static do
  @moduledoc "Encodes static configuration that is the same across all screens of a given type."

  @type time_range :: {start :: Time.t(), stop :: Time.t()}

  defmodule PeriodicAudio do
    @moduledoc """
    Static configuration for screens that read out audio periodically, without rider action.

    Currently, screens that support periodic readouts happen to also be the only screens where we
    can control the volume of readouts, so this configuration is bundled together.
    """

    alias Screens.V2.ScreenData.Static

    @type t :: %__MODULE__{
            day_volume: float(),
            interval_minutes: pos_integer(),
            night_time: Static.time_range(),
            night_volume: float()
          }

    @enforce_keys ~w[day_volume interval_minutes night_time night_volume]a
    defstruct @enforce_keys
  end

  @type t :: %__MODULE__{
          audio_active_time: time_range() | nil,
          candidate_generator: module(),
          periodic_audio: PeriodicAudio.t() | nil,
          refresh_rate: pos_integer(),
          variants: %{String.t() => module()}
        }

  @enforce_keys ~w[candidate_generator refresh_rate]a
  defstruct @enforce_keys ++ [audio_active_time: nil, periodic_audio: nil, variants: %{}]
end
