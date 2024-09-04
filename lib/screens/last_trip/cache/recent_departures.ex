defmodule Screens.LastTrip.Cache.RecentDepartures do
  @moduledoc """
  Cache of recent departures keyed by route-direction-stop tuple (`t:key/0`).

  Values are trip id departure time tuples (`t:value/0`).
  """
  use Nebulex.Cache,
    otp_app: :screens,
    adapter: Nebulex.Adapters.Local

  @type key :: Screens.LastTrip.Cache.rds()
  @type value :: [Screens.LastTrip.Cache.departing_trip()]
end
