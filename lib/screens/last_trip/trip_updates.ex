defmodule Screens.LastTrip.TripUpdates do
  @moduledoc """
  Behaviour and proxying module for fetching trip updates
  """
  @adapter Application.compile_env!(:screens, [Screens.LastTrip, :trip_updates_adapter])

  @callback get() :: {:ok, map()} | {:error, term()}

  defdelegate get, to: @adapter
end
