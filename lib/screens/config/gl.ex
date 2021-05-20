defmodule Screens.Config.Gl do
  @moduledoc false

  alias Screens.Config.PsaConfig

  @type t :: %__MODULE__{
          stop_id: String.t(),
          platform_id: String.t(),
          route_id: String.t(),
          direction_id: 0 | 1,
          headway_mode: boolean(),
          service_level: pos_integer(),
          psa_config: PsaConfig.t(),
          nearby_departures: list(String.t())
        }

  @enforce_keys [:stop_id, :platform_id, :route_id, :direction_id]
  defstruct stop_id: nil,
            platform_id: nil,
            route_id: nil,
            direction_id: nil,
            headway_mode: false,
            service_level: 1,
            psa_config: PsaConfig.from_json(:default),
            nearby_departures: []

  use Screens.Config.Struct, children: [psa_config: PsaConfig]

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
