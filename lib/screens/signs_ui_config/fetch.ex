defmodule Screens.SignsUiConfig.Fetch do
  alias Screens.Cache.Engine

  @callback fetch_config(Engine.table_version()) ::
              {:ok, String.t(), Engine.table_version()} | :unchanged | :error

  @config_fetcher Application.compile_env(:screens, :signs_ui_config_fetcher)

  defdelegate fetch_config(config_version), to: @config_fetcher
end
