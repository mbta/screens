defmodule Screens.LastTrip.Cache do
  @moduledoc """
  Cache of departures times for predictions where `last_trip` is true
  """
  use Nebulex.Cache,
    otp_app: :screens,
    adapter: Nebulex.Adapters.Local

  alias Screens.V2.RDS

  @type key :: destination :: RDS.destination_key()
  @type value :: departure_times :: [DateTime.t()]
end
