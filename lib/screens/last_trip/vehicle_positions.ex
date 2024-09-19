defmodule Screens.LastTrip.VehiclePositions do
  @moduledoc """
  Behaviour and proxying module for fetching vehicle positions
  """
  @adapter Application.compile_env!(:screens, [Screens.LastTrip, :vehicle_positions_adapter])

  @callback get() :: {:ok, map()} | {:error, term()}

  defdelegate get, to: @adapter
end
