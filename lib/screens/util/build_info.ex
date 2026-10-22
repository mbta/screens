defmodule Screens.Util.BuildInfo do
  @moduledoc """
  A utility for retrieving a build information for the running
  application.
  """

  # Evaluated at compile time, so all instances running the same release share this value.
  @build_time DateTime.utc_now()

  @doc """
  Return a datetime that acts as a unique identifier of a build of the project.
  Set at compile time so all instances running the same image share this value.
  """
  @callback datetime() :: DateTime.t()
  def datetime, do: @build_time
end
