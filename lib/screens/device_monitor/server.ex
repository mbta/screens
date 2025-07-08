defmodule Screens.DeviceMonitor.Server do
  @moduledoc """
  Common implementation of a device monitor server.

  The `use`-ing module is expected to define a `log/1` function, which will be called when new
  data should be logged. The argument is a pair of DateTimes indicating the range of data to log
  (for cases where we log timestamped "events" rather than current status of devices). The return
  value is ignored.
  """

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer
      require Logger

      @timer_key to_string(__MODULE__)

      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, :ok, opts)
      end

      @impl true
      def init(:ok) do
        send(self(), :refresh)
        {:ok, nil}
      end

      @impl true
      def handle_info(:refresh, state) do
        {result, next} = Screens.DeviceMonitor.Timer.next(@timer_key, DateTime.utc_now())

        _ =
          case result do
            {:ok, report_range} ->
              Logger.info("#{__MODULE__} running logging")
              Task.start(fn -> log(report_range) end)

            :ignore ->
              Logger.info("#{__MODULE__} skipping logging")
              nil

            {:error, error} ->
              Logger.error("#{__MODULE__} error: #{inspect(error)}")
          end

        Process.send_after(
          self(),
          :refresh,
          DateTime.diff(next, DateTime.utc_now(), :millisecond)
        )

        {:noreply, state}
      end

      # Handle leaked :ssl_closed messages from Hackney.
      # Workaround for this issue: https://github.com/benoitc/hackney/issues/464
      def handle_info({:ssl_closed, _}, state) do
        {:noreply, state}
      end
    end
  end
end
