defmodule Screens.LastTrip.VehiclePositions.Noop do
  @moduledoc "Noop VehiclePositions adapter for testing"
  @behaviour Screens.LastTrip.VehiclePositions

  @impl true
  def get do
    case Jason.decode("{\"entity\":[]}") do
      {:ok, decoded} -> {:ok, %HTTPoison.Response{status_code: 200, body: decoded}}
      error -> error
    end
  end
end
