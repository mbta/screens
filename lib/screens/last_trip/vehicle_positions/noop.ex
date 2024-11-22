defmodule Screens.LastTrip.VehiclePositions.Noop do
  @moduledoc "Noop VehiclePositions adapter for testing"
  @behaviour Screens.LastTrip.VehiclePositions

  @impl true
  def get do
    {:ok, %HTTPoison.Response{status_code: 200, body: %{"entity" => []}}}
  end
end
