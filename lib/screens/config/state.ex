defmodule Screens.Config.State do
  alias Screens.Config

  @type t :: {Config.t(), retry_count :: non_neg_integer()} | :error

  @initial_fetch_wait_ms 500
  @refresh_ms 15 * 1000
  @max_retries 8

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def ok?(pid \\ __MODULE__) do
    GenServer.call(pid, :ok?)
  end

  def schedule_refresh(pid, ms \\ @refresh_ms) do
    Process.send_after(pid, :refresh, ms)
    :ok
  end

  ###

  @impl true
  def init(:ok) do
    config_fetcher = Application.get_env(:screens, :config_fetcher)

    init_state =
      case config_fetcher.fetch_config() do
        {:ok, config} -> {config, 0}
        :error -> :error
      end

    schedule_refresh(self(), @initial_fetch_wait_ms)
    {:ok, init_state}
  end

  @impl true
  def handle_call(:ok?, _from, :error), do: false
  def handle_call(:ok?, _from, {_config, _retry_count}), do: true

  # If we're in an error state, all queries on the state get an :error response
  def handle_call(_, _from, :error) do
    {:reply, :error, :error}
  end

  @impl true
  def handle_info(:refresh, state) do
    config_fetcher = Application.get_env(:screens, :config_fetcher)

    new_state =
      case config_fetcher.fetch_config() do
        {:ok, config} -> {config, 0}
        :error -> error_state(state)
      end

    schedule_refresh(self())
    {:noreply, new_state}
  end

  # Handle leaked :ssl_closed messages from Hackney.
  # Workaround for this issue: https://github.com/benoitc/hackney/issues/464
  def handle_info({:ssl_closed, _}, state) do
    {:noreply, state}
  end

  @spec error_state(t()) :: t()
  defp error_state(:error) do
    :error
  end

  defp error_state({_config, retry_count}) when retry_count >= @max_retries do
    :error
  end

  defp error_state({config, retry_count}) do
    {config, retry_count + 1}
  end
end
