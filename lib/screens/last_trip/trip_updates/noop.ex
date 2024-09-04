defmodule Screens.LastTrip.TripUpdates.Noop do
  @moduledoc "Noop TripUpdates adapter for testing"
  @behaviour Screens.LastTrip.TripUpdates

  @impl true
  def get do
    {:ok, %{status_code: 200, body: %{"entity" => []}}}
  end
end
