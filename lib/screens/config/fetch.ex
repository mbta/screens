defmodule Screens.Config.Fetch do
  @moduledoc """
  Defines a behaviour for, and delegates to, a module that provides access to
  the screens config file.
  """

  alias Screens.Cache.Engine

  @type fetch_result :: {:ok, String.t(), Engine.table_version()} | :unchanged | :error

  @callback fetch_config(Engine.table_version()) :: fetch_result
  @callback fetch_config() :: fetch_result

  @callback put_config(String.t()) :: :ok | :error

  # The module adopting this behaviour that we use for the current environment.
  @config_fetcher Application.compile_env(:screens, :config_fetcher)

  # These delegates let other modules call functions from the appropriate Fetch module
  # without having to know which it is.
  defdelegate fetch_config(config_version), to: @config_fetcher
  defdelegate fetch_config(), to: @config_fetcher
  defdelegate put_config(file_contents), to: @config_fetcher
end
