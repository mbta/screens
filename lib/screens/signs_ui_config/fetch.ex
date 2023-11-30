defmodule Screens.SignsUiConfig.Fetch do
  @moduledoc """
  Defines a behaviour for, and delegates to, a module that provides access to
  the Signs UI config file.
  """

  alias Screens.Cache.Engine

  @type fetch_result :: {:ok, String.t(), Engine.table_version()} | :unchanged | :error

  @callback fetch_config(Engine.table_version()) :: fetch_result
  @callback fetch_config() :: fetch_result

  @config_fetcher Application.compile_env(:screens, :signs_ui_config_fetcher)

  defdelegate fetch_config(config_version), to: @config_fetcher
  defdelegate fetch_config(), to: @config_fetcher
end
