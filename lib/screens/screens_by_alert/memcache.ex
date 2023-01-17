defmodule Screens.ScreensByAlert.Memcache do
  @moduledoc """
  ScreensByAlert backend which uses memcached as a backend.

  This is intended to be used as a singleton process--all public functions in the module
  communicate with a named process that maintains a connection with memcached.

  Structure of cached data:
  ```
  # A Unix timestamp
  @type timestamp :: integer()

  @type screen_id :: String.t()
  @type alert_id :: String.t()

  @type timestamped_screen_id :: {screen_id, timestamp}

  %{
    # Each alert is mapped to a list of screens showing it.
    # Each screen in the list is paired with a timestamp of the last
    # time it declared that it was showing this alert.
    "screens_by_alert." <> alert_id => list(timestamped_screen_id),

    # Metadata to make the "self-refresh" mechanism possible
    "screens_last_updated." <> screen_id => timestamp
  }
  ```
  """
  alias Screens.ScreensByAlert.Memcache.TaskSupervisor

  require Logger

  @behaviour Screens.ScreensByAlert.Behaviour

  @server __MODULE__.Server

  @screens_by_alert_key_prefix "screens_by_alert."
  @screens_last_updated_key_prefix "screens_last_updated."

  @config Application.compile_env!(:screens, :screens_by_alert)
  @screens_by_alert_ttl Keyword.fetch!(@config, :screens_by_alert_ttl_seconds)
  @screens_last_updated_ttl Keyword.fetch!(@config, :screens_last_updated_ttl_seconds)
  @screens_ttl Keyword.fetch!(@config, :screens_ttl_seconds)

  @impl true
  def start_link(_opts) do
    module_config = Application.fetch_env!(:screens, Screens.ScreensByAlert.Memcache)
    connection_opts = Keyword.fetch!(module_config, :connection_opts)

    Memcache.start_link(connection_opts, name: @server)
  end

  @impl true
  def put_data(screen_id, alert_ids, store_screen_id) when is_binary(screen_id) and is_list(alert_ids) do
    now = System.system_time(:second)

    # To avoid bottlenecks and unnecessarily blocking the caller, run in a separate task process
    _ =
      Task.Supervisor.start_child(TaskSupervisor, fn ->
        update_screens_last_updated_key(screen_id, now)
        Enum.each(alert_ids, &update_alert_key(&1, screen_id, now, store_screen_id))
      end)

    :ok
  end

  @impl true
  def get_screens_by_alert(alert_ids) when is_list(alert_ids) do
    now = System.system_time(:second)
    cache_keys = Enum.map(alert_ids, &alert_key/1)

    case Memcache.multi_get(@server, cache_keys) do
      {:ok, cache_result_map} ->
        Map.new(cache_result_map, &clean_up_alert_cache_item(&1, now))

      {:error, message} ->
        Logger.warn("[get_screens_by_alert memcache error] message=\"#{message}\"")
        # Should we return an error tuple instead of the default map?
        # TODO: return the error tuple
    end
  end

  @impl true
  def get_screens_last_updated(screen_ids) when is_list(screen_ids) do
    default_map = Map.new(screen_ids, &{&1, 0})
    cache_keys = Enum.map(screen_ids, &last_updated_key/1)

    case Memcache.multi_get(@server, cache_keys) do
      {:ok, cache_result_map} ->
        found_items = Map.new(cache_result_map, &clean_up_screens_last_updated_cache_item/1)
        Map.merge(default_map, found_items)

      {:error, message} ->
        Logger.warn("[get_screens_last_updated memcache error] message=\"#{message}\"")
        # Should we return an error tuple instead of the default map?
        default_map
    end
  end

  defp update_screens_last_updated_key(screen_id, now) do
    set_result =
      Memcache.set(@server, last_updated_key(screen_id), now, ttl: @screens_last_updated_ttl)

    _ =
      case set_result do
        {:error, message} ->
          Logger.warn(
            "[put_data screens_last_updated memcache error] screen_id=#{screen_id} message=#{message}"
          )

        _ ->
          :ok
      end
  end

  # Creates or updates the cache item for the given alert ID with the given screen ID, retrying until success.
  # In the process of updating existing screen IDs under the alert key, this also removes
  # any screen IDs that have expired.
  defp update_alert_key(alert_id, screen_id, now, store_screen_id) do
    key = alert_key(alert_id)
    new_timestamped_screen_id = {screen_id, now}

    cas_result =
      Memcache.cas(
        @server,
        key,
        timestamped_screens_updater_fn(new_timestamped_screen_id, store_screen_id),
        retry: true,
        default: [new_timestamped_screen_id],
        ttl: @screens_by_alert_ttl
      )

    case cas_result do
      {:error, message} ->
        Logger.warn(
          "[put_data screens_by_alert memcache error] alert_id=#{alert_id} screen_id=#{screen_id} message=#{message}"
        )

      _ ->
        :ok
    end
  end

  defp timestamped_screens_updater_fn({_id, now} = new_timestamped_screen_id, store_screen_id) do
    fn timestamped_screen_ids ->
      unexpired_ids =
        Enum.reject(timestamped_screen_ids, fn {_id, timestamp} ->
          timestamp + @screens_ttl < now
        end)

      if store_screen_id, do: [new_timestamped_screen_id | unexpired_ids], else: [unexpired_ids]
    end
  end

  # Restores alert ID from prefixed cache key, removes expired screen IDs from the list,
  # and strips screen IDs of their timestamps.
  defp clean_up_alert_cache_item(
         {cache_key, timestamped_screen_ids},
         now
       ) do
    screen_ids =
      timestamped_screen_ids
      |> Enum.reject(fn {_screen_id, timestamp} -> timestamp + @screens_ttl < now end)
      |> Enum.map(fn {screen_id, _timestamp} -> screen_id end)
      |> Enum.uniq()

    {key_to_id(cache_key), screen_ids}
  end

  defp clean_up_screens_last_updated_cache_item({cache_key, timestamp}) do
    {key_to_id(cache_key), timestamp}
  end

  defp alert_key(alert_id), do: @screens_by_alert_key_prefix <> alert_id
  defp last_updated_key(screen_id), do: @screens_last_updated_key_prefix <> screen_id

  defp key_to_id(@screens_by_alert_key_prefix <> alert_id), do: alert_id
  defp key_to_id(@screens_last_updated_key_prefix <> screen_id), do: screen_id
end
