defmodule Screens.SignsUiConfig.State do
  @moduledoc false

  alias Screens.ConfigCache.State.Fetch

  @typep mode :: :auto | :headway | :off | :static_text
  @typep signs_mode_map :: %{String.t() => mode}
  @typep time_range :: {non_neg_integer(), non_neg_integer()}
  @typep time_range_map :: %{peak: time_range, off_peak: time_range}
  @type config :: {signs_mode_map, time_range_map}
  @config_fetcher Application.get_env(:screens, :signs_ui_config_fetcher)

  @type t ::
          %__MODULE__{
            config: config,
            retry_count: non_neg_integer(),
            version_id: Fetch.version_id()
          }
          | :error

  @enforce_keys [:config]
  defstruct config: nil,
            retry_count: 0,
            version_id: nil

  use Screens.ConfigCache.State,
    config_module: Screens.SignsUiConfig.State,
    fetch_config_fn: &@config_fetcher.fetch_config/1,
    refresh_ms: 60 * 1000,
    fetch_failure_error_threshold_minutes: 2

  def all_signs_in_headway_mode?(pid \\ __MODULE__, sign_ids) do
    all_signs_in_modes?(pid, sign_ids, [:headway])
  end

  def all_signs_inactive?(pid \\ __MODULE__, sign_ids) do
    all_signs_in_modes?(pid, sign_ids, [:off, :static_text])
  end

  defp all_signs_in_modes?(_pid, [], _modes), do: false

  defp all_signs_in_modes?(pid, sign_ids, modes) do
    GenServer.call(pid, {:all_signs_in_modes, sign_ids, modes})
  end

  def time_ranges(pid \\ __MODULE__, line_or_trunk) do
    GenServer.call(pid, {:time_ranges, line_or_trunk})
  end

  def time_period(utc_time) do
    {:ok, dt} = DateTime.shift_zone(utc_time, "America/New_York")
    day_of_week = dt |> DateTime.to_date() |> Date.day_of_week()

    weekday? = day_of_week in 1..5

    rush_hour? =
      dt.hour in 7..8 or dt.hour in 16..17 or
        (dt.hour == 18 and dt.minute <= 30)

    if(weekday? and rush_hour?, do: :peak, else: :off_peak)
  end

  ###

  @impl true
  def handle_call(
        {:all_signs_in_modes, sign_ids, modes},
        _from,
        %__MODULE__{config: config} = state
      ) do
    {sign_mode_map, _} = config

    result =
      Enum.all?(sign_ids, fn sign_id -> Enum.member?(modes, Map.get(sign_mode_map, sign_id)) end)

    {:reply, result, state}
  end

  def handle_call({:time_ranges, line_or_trunk}, _from, %__MODULE__{config: config} = state) do
    {_, time_ranges} = config
    result = Map.get(time_ranges, line_or_trunk)

    {:reply, result, state}
  end

  def handle_call(_, _from, :error) do
    {:reply, :error, :error}
  end
end
