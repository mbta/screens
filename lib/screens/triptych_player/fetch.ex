defmodule Screens.TriptychPlayer.Fetch do
  @moduledoc """
  Defines a behaviour for, and delegates to, a module that provides access to
  the triptych player config file.
  """

  alias Screens.Cache.Engine

  @callback fetch_config(Engine.table_version()) ::
              {:ok, String.t(), Engine.table_version()} | :unchanged | :error

  @callback put_config(String.t()) :: :ok | :error

  alias Screens.Cache.Engine

  @config_fetcher Application.compile_env(:screens, :triptych_player_fetcher)

  defdelegate fetch_config(config_version), to: @config_fetcher
  defdelegate fetch_config(), to: @config_fetcher
  defdelegate put_config(file_contents), to: @config_fetcher
end
