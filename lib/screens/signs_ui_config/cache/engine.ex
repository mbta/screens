defmodule Screens.SignsUiConfig.Cache.Engine do
  @moduledoc """
  Engine for the Signs UI config cache.
  """

  alias Screens.SignsUiConfig.{Fetch, Parse}

  @behaviour Screens.Cache.Engine

  @impl true
  def name, do: Screens.SignsUiConfig.Cache.table()

  @impl true
  def update_table(current_version) do
    with {:ok, file_contents, new_version} <- Fetch.fetch_config(current_version),
         {:ok, decoded_config} <- Jason.decode(file_contents) do
      {:replace, Parse.parse_config(decoded_config), new_version}
    else
      :unchanged -> :unchanged
      _ -> :error
    end
  end

  @impl true
  def update_interval_ms, do: 60_000
end
