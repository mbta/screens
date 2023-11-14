defmodule Screens.ConfigCache.Owner do
  @moduledoc """
  A GenServer responsible for creating, owning, and handling all writes to an ETS-table-based cache.

  Functions that read the cache data should be defined in the client module.
  This module is not concerned with what the table's contents look like,
  or what kinds of queries will be made against it.

  The calling module should pass a map to `start_link` that specifies the table name, and how and when to fetch data.
  Whenever new data is received, the table's entire contents are replaced by the new data.
  """

  use GenServer

  @type t :: %__MODULE__{
          ### Properties specified by cache_opts
          fetch_config: function(),
          name: any(),
          refresh_ms: non_neg_integer,
          fetch_failure_error_log_threshold_minutes: non_neg_integer,

          ### Cache state
          config_version: config_version(),
          retry_count: non_neg_integer(),
          # The server initializes in error state, and transitions permanently to ok after its first successful config fetch.
          status: :ok | :error
        }

  @typedoc """
  Settings for the cache. All fields are required.
  """
  @type cache_opts :: %{
          fetch_config: (config_version -> fetch_success | :unchanged | :error),
          name: atom(),
          refresh_ms: non_neg_integer,
          fetch_failure_error_log_threshold_minutes: non_neg_integer
        }

  @typedoc """
  To be returned by fetch_config on success.

  new_table_entries must be a tuple or list of tuples, for compatibility with ETS.
  The first element of each tuple is used as the table lookup key for that entry.
  """
  @type fetch_success ::
          {:ok, new_table_entries :: tuple | list(tuple), new_version :: config_version}

  @typedoc """
  Any value representing the current version of the config.
  This is usually an S3 ETag.

  Always starts out as nil, since we haven't fetched data (and its version metadata) yet.
  """
  @type config_version :: any | nil

  @enforce_keys [:fetch_config, :name, :refresh_ms, :fetch_failure_error_log_threshold_minutes]
  defstruct @enforce_keys ++ [config_version: nil, retry_count: 0, status: :error]

  ### Client

  @doc """
  Starts up a GenServer process that creates, owns, and handles all writes to a named cache table.
  """
  @spec start_link(cache_opts, GenServer.options()) :: GenServer.on_start()
  def start_link(cache_opts, gen_server_opts \\ []) do
    GenServer.start_link(__MODULE__, cache_opts, gen_server_opts)
  end

  ### Server

  @impl true
  def init(cache_opts) do
    init_state = %__MODULE__{
      fetch_config: cache_opts.fetch_config,
      name: cache_opts.name,
      refresh_ms: cache_opts.refresh_ms,
      fetch_failure_error_log_threshold_minutes:
        cache_opts.fetch_failure_error_log_threshold_minutes
    }

    state = fetch_and_update_table(init_state)

    schedule_refresh(cache_opts.refresh_ms)
    {:ok, state}
  end

  @impl true
  def handle_info(:refresh, state) do
    schedule_refresh(state.refresh_ms)

    {:noreply, fetch_and_update_table(state)}
  end

  # Handle leaked :ssl_closed messages from Hackney.
  # Workaround for this issue: https://github.com/benoitc/hackney/issues/464
  def handle_info({:ssl_closed, _}, state) do
    {:noreply, state}
  end

  defp schedule_refresh(refresh_ms) do
    unless refresh_ms == 0, do: Process.send_after(self(), :refresh, refresh_ms)
  end

  defp fetch_and_update_table(state) do
    case state.fetch_config.(state.config_version) do
      {:ok, new_table_entries, new_config_version} ->
        :ok = ensure_table_created(state)
        replace_contents(state.name, new_table_entries)

        %{state | config_version: new_config_version, retry_count: 0, status: :ok}

      :unchanged ->
        %{state | retry_count: 0, status: :ok}

      :error ->
        error_state(state)
    end
  end

  defp ensure_table_created(%{status: :ok}), do: :ok

  defp ensure_table_created(state) do
    _table = :ets.new(state.name, [:named_table, read_concurrency: true])
    :ok
  end

  # Safely replaces table contents.
  #
  # ETS doesn't support atomic bulk writes, so we can't just clear the whole table
  # (:ets.delete_all_objects/1) and then insert all of the new entries (:ets.insert/2),
  # because that would leave the table completely empty for a short period, causing any concurrent reads during that time to fail.
  #
  # Instead, we remove only the table entries that are absent from new_entries.
  defp replace_contents(table, new_entry) when is_tuple(new_entry) do
    replace_contents(table, [new_entry])
  end

  defp replace_contents(table, new_entries) do
    new_keys = MapSet.new(new_entries, &elem(&1, 0))
    current_table_keys = keys(table)

    removed_keys = MapSet.difference(current_table_keys, new_keys)
    Enum.each(removed_keys, &:ets.delete(table, &1))

    # Insert/update the new entries. (Analogous to Map.merge/2)
    :ets.insert(table, new_entries)
  end

  # Returns a MapSet of all keys in the table.
  defp keys(table) do
    keys(table, :ets.first(table), [])
  end

  defp keys(table, :"$end_of_table", acc), do: MapSet.new(acc)

  defp keys(table, key, acc) do
    keys(table, :ets.next(table, key), [key | acc])
  end

  defp error_state(%{status: :error} = state) do
    _ = Logger.error("config_state_init_fetch_error")

    %{state | retry_count: state.retry_count + 1}
  end

  defp error_state(state) do
    log_message = "config_state_fetch_error table_name=#{state.name} retry_count=#{retry_count}"

    if log_as_error?(state) do
      Logger.error(log_message)
    else
      Logger.warn(log_message)
    end

    %{state | retry_count: state.retry_count + 1}
  end

  defp log_as_error?(state) do
    threshold_ms = state.fetch_failure_error_log_threshold_minutes * 60_000

    state.retry_count * state.refresh_ms >= threshold_ms
  end
end
