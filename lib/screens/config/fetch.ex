defmodule Screens.Config.Fetch do
  @moduledoc false

  alias Screens.Cache.Engine

  @callback fetch_config(Engine.table_version()) ::
              {:ok, String.t(), Engine.table_version()} | :unchanged | :error

  @callback put_config(String.t()) :: :ok | :error

  # The module adopting this behaviour that we use for the current environment.
  @config_fetcher Application.compile_env(:screens, :config_fetcher)

  # These delegates let other modules call functions from the appropriate Fetch module
  # without having to know which it is.
  defdelegate fetch_config(config_version), to: @config_fetcher
  defdelegate put_config(file_contents), to: @config_fetcher
end
