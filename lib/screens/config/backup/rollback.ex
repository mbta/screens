defmodule Screens.Config.Backup.Rollback do
  @moduledoc """
  Operations to manage rollbacks to dated screen configuration backups.

  Rollbacks affect screen configurations persisted in Postgres within the current evnrionment only.
  """

  import Screens.Inject

  alias Screens.Config.Backup
  alias Screens.Config.ScreenConfig
  alias Screens.ScreenConfigs
  alias ScreensConfig.Screen

  @store injected(Screens.Config.Backup.Store)

  @type comparison_result :: %{current: map(), backup: map(), differing_ids: [String.t()]}
  @type restore_error ::
          :backup_fetch_failed
          | :backup_invalid
          | {:backup_decode_failed, Jason.DecodeError.t()}
          | :invalid_date

  @doc "Dates for which the current environment has a daily config backup."
  @spec dates() :: {:ok, [String.t()]} | :error
  def dates do
    case @store.list_daily(Backup.environment_name()) do
      {:ok, dates} -> {:ok, Enum.sort(dates, :desc)}
      :error -> :error
    end
  end

  @doc "Returns current and dated backup screen configs for comparison."
  @spec compare_daily(String.t()) ::
          {:ok, comparison_result()} | {:error, restore_error()}
  def compare_daily(date) do
    with {:ok, backup_configs} <- configs_from_date(date) do
      {:ok, compare_screens(backup_configs)}
    end
  end

  @doc "Replaces persisted screen configs with the current environment's backup from a date."
  @spec restore_daily(String.t()) :: {:ok, map()} | {:error, restore_error()}
  def restore_daily(date) do
    with {:ok, backup_screens} <- configs_from_date(date),
         comparison = compare_screens(backup_screens),
         updates =
           Enum.map(comparison.backup, fn {id, config} -> %{id: id, config: config} end),
         deletes = Map.keys(comparison.current) -- Map.keys(comparison.backup),
         :ok <- commit_daily_changes(updates, deletes) do
      {:ok, %{upserted: length(updates), deleted: length(deletes)}}
    end
  end

  @spec compare_screens(map()) :: comparison_result()
  defp compare_screens(backup_configs) do
    current_configs =
      ScreenConfigs.all()
      |> Map.new(fn %ScreenConfig{id: id, config: config} ->
        {id, Screen.to_json(config)}
      end)
      |> normalize_json()

    differing_ids =
      current_configs
      |> Map.keys()
      |> Kernel.++(Map.keys(backup_configs))
      |> Enum.uniq()
      |> Enum.reject(&(Map.get(current_configs, &1) == Map.get(backup_configs, &1)))
      |> Enum.sort()

    %{
      current: Map.take(current_configs, differing_ids),
      backup: Map.take(backup_configs, differing_ids),
      differing_ids: differing_ids
    }
  end

  @spec configs_from_date(String.t()) ::
          {:ok, map()} | {:error, restore_error()}
  defp configs_from_date(date) do
    with {:ok, parsed_date} <- Date.from_iso8601(date),
         {:ok, json} <- @store.fetch_daily(Backup.environment_name(), parsed_date),
         {:ok, %{"screens" => screens}} when is_map(screens) <- Jason.decode(json) do
      {:ok, screens}
    else
      {:ok, _decoded} -> {:error, :backup_invalid}
      {:error, :invalid_format} -> {:error, :invalid_date}
      {:error, :invalid_date} -> {:error, :invalid_date}
      :error -> {:error, :backup_fetch_failed}
      {:error, %Jason.DecodeError{} = error} -> {:error, {:backup_decode_failed, error}}
    end
  end

  # Ensures consistent formatting of JSON maps before comparison, since key ordering in a map isn't guaranteed.
  defp normalize_json(map), do: map |> Jason.encode!() |> Jason.decode!()

  @spec commit_daily_changes([map()], [String.t()]) :: :ok | {:error, term()}
  defp commit_daily_changes([], []), do: :ok

  defp commit_daily_changes(updates, deletes),
    do: ScreenConfigs.commit_updates(updates, deletes)
end
