defmodule Screens.SignsUiConfig.State do
  @moduledoc false

  alias Screens.ConfigCache.State.Fetch

  @typep signs_list :: [String.t()]
  @typep time_range :: {non_neg_integer(), non_neg_integer()}
  @typep time_range_map :: %{peak: time_range, off_peak: time_range}
  @type config :: {signs_list, time_range_map}
  @type t :: {config, retry_count :: non_neg_integer(), Fetch.version_id()} | :error
  @config_fetcher Application.get_env(:screens, :signs_ui_config_fetcher)

  use Screens.ConfigCache.State,
    fetch_config_fn: &@config_fetcher.fetch_config/1,
    refresh_ms: 60 * 1000,
    fetch_failure_error_threshold_minutes: 2

  def sign_in_headway_mode?(pid \\ __MODULE__, sign_id) do
    GenServer.call(pid, {:sign_in_headway_mode, sign_id})
  end

  def all_signs_in_headway_mode?(pid \\ __MODULE__, sign_ids) do
    GenServer.call(pid, {:all_signs_in_headway_mode, sign_ids})
  end

  def time_ranges(pid \\ __MODULE__, line_or_trunk) do
    GenServer.call(pid, {:time_ranges, line_or_trunk})
  end

  ###

  @impl true
  def handle_call({:sign_in_headway_mode, sign_id}, _from, {config, _, _} = state) do
    {signs_in_headway_mode, _} = config
    result = Enum.member?(signs_in_headway_mode, sign_id)

    {:reply, result, state}
  end

  def handle_call({:all_signs_in_headway_mode, sign_ids}, _from, {config, _, _} = state) do
    {signs_in_headway_mode, _} = config
    result = Enum.all?(sign_ids, fn sign_id -> Enum.member?(signs_in_headway_mode, sign_id) end)

    {:reply, result, state}
  end

  def handle_call({:time_ranges, line_or_trunk}, _from, {config, _, _} = state) do
    {_, time_ranges} = config
    result = Map.get(time_ranges, line_or_trunk)

    {:reply, result, state}
  end

  def handle_call(_, _from, :error) do
    {:reply, :error, :error}
  end
end
