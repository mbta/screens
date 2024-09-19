defmodule Screens.LastTrip.Cache.LastTrips do
  @moduledoc """
  Cache of Trip IDs (`t:key/0`) where `last_trip` was `true` (`t:value/0`).
  """
  use Nebulex.Cache,
    otp_app: :screens,
    adapter: Nebulex.Adapters.Local

  @type key :: trip_id :: String.t()
  @type value :: last_trip? :: true
end
