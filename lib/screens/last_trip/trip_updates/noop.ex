defmodule Screens.LastTrip.TripUpdates.Noop do
  @moduledoc "Noop TripUpdates adapter for testing"
  @behaviour Screens.LastTrip.TripUpdates

  @impl true
  def get do
    case Jason.decode("{\"entity\":[]}") do
      {:ok, decoded} -> {:ok, %{status_code: 200, body: decoded}}
      error -> error
    end
  end
end
