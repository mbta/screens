defmodule Screens.SignsUiConfig.Cache.Engine do
  alias Screens.SignsUiConfig.Cache
  alias Screens.SignsUiConfig.Parse
  alias Screens.SignsUiConfig.Fetch

  @behaviour Screens.Cache.Engine

  @impl true
  def name, do: Screens.SignsUiConfig.Cache.table()

  @impl true
  def update_table(current_version) do
    with {:ok, body, new_version} <- Fetch.fetch_config(current_version),
         {:ok, deserialized} <- Jason.decode(body) do
      config = Parse.parse_config(deserialized)

      table_entries = config_to_table_entries(config)

      {:replace, table_entries, new_version}
    else
      :unchanged -> :unchanged
      _ -> :error
    end
  end

  @impl true
  def update_interval_ms, do: 60_000

  @impl true
  def update_failure_error_log_threshold_minutes, do: 2

  @spec config_to_table_entries(config :: tuple()) :: Cache.table_contents()
  defp config_to_table_entries({sign_modes, time_ranges}) do
    sign_modes = Enum.map(sign_modes, fn {id, mode} -> {{:sign_mode, id}, mode} end)

    time_ranges = Enum.map(time_ranges, fn {id, ranges} -> {{:time_ranges, id}, ranges} end)

    sign_modes ++ time_ranges
  end
end
