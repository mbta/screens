defmodule Screens.Util.BuildInfo do
  @moduledoc """
  A utility for retrieving a build information for the running
  application.
  """

  @doc """
  Return an identifier that uniquely identifies a build of the project.
  """
  @callback build_identifier :: String.t()
  def build_identifier() do
    Application.fetch_env!(:screens, :build_identifier)
  end
end
