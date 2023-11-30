defmodule Screens.TriptychPlayer.Cache.Engine do
  @moduledoc """
  Engine for the triptych player config cache.
  """

  alias Screens.TriptychPlayer.Fetch

  @behaviour Screens.Cache.Engine

  @impl true
  def name, do: Screens.TriptychPlayer.Cache.table()

  @impl true
  def update_table(current_version) do
    with {:ok, body, new_version} <- Fetch.fetch_config(current_version),
         {:ok, deserialized} <- Jason.decode(body) do
      table_entries = Map.to_list(deserialized)

      {:replace, table_entries, new_version}
    else
      :unchanged -> :unchanged
      _ -> :error
    end
  end

  @impl true
  def update_interval_ms, do: 15_000

  @impl true
  def update_failure_error_log_threshold_minutes, do: 0
end
