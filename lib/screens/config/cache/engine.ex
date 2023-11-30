defmodule Screens.Config.Cache.Engine do
  alias Screens.Config
  alias Screens.Config.Cache
  alias Screens.Config.Fetch

  @behaviour Screens.Cache.Engine

  @last_deploy_fetcher Application.compile_env(:screens, :last_deploy_fetcher)

  @impl true
  def name, do: Screens.Config.Cache.table()

  @impl true
  def update_table(current_version) do
    last_deploy_timestamp = @last_deploy_fetcher.get_last_deploy_time()

    with {:ok, body, new_version} <- Fetch.fetch_config(current_version),
         {:ok, deserialized} <- Jason.decode(body) do
      config = Config.from_json(deserialized)

      # It's inefficient to store the entire config under one key--every time we read any entry from an ETS table,
      # a full copy of that entry is made.
      # So, we need to split the config into separate entries for each screen, plus a couple metadata items.
      table_entries = config_to_table_entries(config, last_deploy_timestamp)

      {:replace, table_entries, new_version}
    else
      :unchanged -> {:patch, {:last_deploy_timestamp, last_deploy_timestamp}}
      _ -> :error
    end
  end

  @impl true
  def update_interval_ms, do: 15_000

  @impl true
  def update_failure_error_log_threshold_minutes, do: 2

  @spec config_to_table_entries(Config.t(), DateTime.t() | nil) :: Cache.table_contents()
  defp config_to_table_entries(config, last_deploy_timestamp) do
    screen_entries =
      Enum.map(config.screens, fn {screen_id, screen_config} ->
        {{:screen, screen_id}, screen_config}
      end)

    metadata_entries = [last_deploy_timestamp: last_deploy_timestamp, devops: config.devops]

    metadata_entries ++ screen_entries
  end
end
