defmodule Screens.PendingConfig.Fetch do
  @moduledoc """
  Defines a behaviour for, and delegates to, a module that provides access to
  the config file for pending screens.
  """
  @callback fetch_config() :: {:ok, String.t()} | :error

  @callback put_config(String.t()) :: :ok | :error

  # The module adopting this behaviour that we use for the current environment.
  @config_fetcher Application.compile_env(:screens, :pending_config_fetcher)

  # These delegates let other modules call functions from the appropriate Fetch module
  # without having to know which it is.
  defdelegate fetch_config(), to: @config_fetcher
  defdelegate put_config(file_contents), to: @config_fetcher
end
