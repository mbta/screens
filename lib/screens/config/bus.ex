defmodule Screens.Config.Bus do
  @moduledoc false

  alias Screens.Config.NearbyConnections
  alias Screens.Config.PsaConfig

  @type t :: %__MODULE__{
          stop_id: String.t(),
          service_level: pos_integer(),
          psa_config: PsaConfig.t(),
          nearby_connections: NearbyConnections.t()
        }

  @enforce_keys [:stop_id]
  defstruct stop_id: nil,
            service_level: 1,
            psa_config: PsaConfig.from_json(:default),
            nearby_connections: NearbyConnections.from_json(:default)

  use Screens.Config.Struct,
    children: [psa_config: PsaConfig, nearby_connections: NearbyConnections]

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
