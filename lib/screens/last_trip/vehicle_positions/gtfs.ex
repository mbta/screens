defmodule Screens.LastTrip.VehiclePositions.GTFS do
  @moduledoc """
  Screens.LastTrip.VehiclePositions adapter that fetches trip updates from
  GTFS
  """
  @behaviour Screens.LastTrip.VehiclePositions

  use Retry.Annotation

  @impl true
  @retry with: Stream.take(constant_backoff(500), 5)
  def get do
    vehicle_positions_url = Application.fetch_env!(:screens, :vehicle_positions_url)

    with {:ok, %{body: body} = response} <- HTTPoison.get(vehicle_positions_url),
         {:ok, decoded} <- Jason.decode(body) do
      {:ok, %{response | body: decoded}}
    end
  end
end
