defmodule Screens.LastTrip.TripUpdates.GTFS do
  @moduledoc """
  Screens.LastTrip.TripUpdates adapter that fetches trip updates from
  GTFS
  """
  @behaviour Screens.LastTrip.TripUpdates

  use Retry.Annotation

  @impl true
  @retry with: Stream.take(constant_backoff(500), 5)
  def get do
    trip_updates_url = Application.fetch_env!(:screens, :trip_updates_url)

    with {:ok, %{body: body} = response} <- HTTPoison.get(trip_updates_url),
         {:ok, decoded} <- Jason.decode(body) do
      {:ok, %{response | body: decoded}}
    end
  end
end
