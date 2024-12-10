defmodule Screens.Cache.Owner do
  @moduledoc """
  A GenServer responsible for creating, owning, and handling all writes to an ETS-table-based cache.

  Once started, the process does not respond to any calls/casts--it's simply a background process.

  Functions that read the cache data should be defined in a separate client module.
  This module is not concerned with what the table's contents look like,
  or what kinds of queries will be made against it.
  """
  alias Screens.Cache.Engine
  alias Screens.Log

  use GenServer

  @type t :: %__MODULE__{
          ### Properties specified by engine module
          name: any(),
          update_table: (Engine.table_version() -> Engine.update_result()),
          update_interval_ms: non_neg_integer,

          ### Cache state
          table_version: Engine.table_version(),
          retry_count: non_neg_integer(),
          # The server initializes in error state, and transitions permanently to ok after its first successful data fetch.
          status: :ok | :error
        }

  @enforce_keys [:name, :update_table, :update_interval_ms]
  defstruct @enforce_keys ++ [table_version: nil, retry_count: 0, status: :error]

  ### Client

  @doc """
  Starts up a GenServer process that creates, owns, and handles all writes to a named cache table.

  The engine module argument specifies behavior of this particular cache instance.
  """
  @spec start_link([engine_module: Engine.t()], GenServer.options()) :: GenServer.on_start()
  def start_link([engine_module: engine], gen_server_opts \\ []) do
    cache_opts = %{
      name: engine.name(),
      update_table: &engine.update_table/1,
      update_interval_ms: engine.update_interval_ms()
    }

    GenServer.start_link(__MODULE__, cache_opts, gen_server_opts)
  end

  # Overrides the default child_spec/1 defined by `use GenServer`, because we need
  # a unique ID for each cache owner that we spin up.
  # The table name provided by the engine must be unique, so let's use that!
  def child_spec(init_arg) do
    table_name = init_arg[:engine_module].name()

    init_arg
    |> super()
    |> Map.replace!(:id, :"#{table_name}_cache_owner")
  end

  ### Server

  @impl true
  def init(cache_opts) do
    init_state = %__MODULE__{
      update_table: cache_opts.update_table,
      name: cache_opts.name,
      update_interval_ms: cache_opts.update_interval_ms
    }

    state = do_update(init_state)

    _ = schedule_update(cache_opts.update_interval_ms)
    {:ok, state}
  end

  @impl true
  def handle_info(:update, state) do
    _ = schedule_update(state.update_interval_ms)

    {:noreply, do_update(state)}
  end

  # Handle leaked :ssl_closed messages from Hackney.
  # Workaround for this issue: https://github.com/benoitc/hackney/issues/464
  def handle_info({:ssl_closed, _}, state) do
    {:noreply, state}
  end

  defp schedule_update(update_interval_ms) do
    unless update_interval_ms == 0, do: Process.send_after(self(), :update, update_interval_ms)
  end

  defp do_update(state) do
    case state.update_table.(state.table_version) do
      {:replace, table_entries, table_version} ->
        :ok = ensure_table_created(state)
        replace_contents(state.name, table_entries)

        %{state | table_version: table_version, retry_count: 0, status: :ok}

      {:patch, updated_table_entries} ->
        :ok = ensure_table_created(state)
        :ets.insert(state.name, updated_table_entries)

        # We don't change `status` in this case, because if
        # we receive a patch update on init (while status is :error),
        # something probably went wrong and we don't have all necessary data.
        # So status remains either :ok or :error.
        %{state | retry_count: 0}

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
  # because that would leave the table completely empty for a short period,
  # causing any concurrent reads during that time to fail.
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

  defp keys(_table, :"$end_of_table", acc), do: MapSet.new(acc)

  defp keys(table, key, acc) do
    keys(table, :ets.next(table, key), [key | acc])
  end

  defp error_state(%{status: :error} = state) do
    Log.error("cache_init_error", table_name: state.name)
    %{state | retry_count: state.retry_count + 1}
  end

  defp error_state(state) do
    Log.error("cache_update_error", table_name: state.name, retry_count: state.retry_count)
    %{state | retry_count: state.retry_count + 1}
  end
end
