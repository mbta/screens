defmodule Screens.ConfigCache.State do
  @moduledoc false

  defmacro __using__(
             config_module: config_module,
             fetch_config_fn: fetch_config,
             refresh_ms: refresh_ms,
             fetch_failure_error_threshold_minutes: fetch_failure_error_threshold_minutes
           ) do
    quote do
      use GenServer

      require Logger

      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, :ok, opts)
      end

      def schedule_refresh(pid, ms \\ unquote(refresh_ms)) do
        Process.send_after(pid, :refresh, ms)
        :ok
      end

      def put_config(pid, config, version) do
        GenServer.cast(pid, {:put_config, config, version})
      end

      def put_fetch_error(pid) do
        GenServer.cast(pid, :put_fetch_error)
      end

      ###
      @impl true
      def init(:ok) do
        init_state =
          case unquote(fetch_config).(nil) do
            {:ok, config, new_version} ->
              %unquote(config_module){config: config, retry_count: 0, version_id: new_version}

            :error ->
              error_state(:error)
          end

        schedule_refresh(self(), unquote(refresh_ms))
        {:ok, init_state}
      end

      @impl true
      def handle_info(
            :refresh,
            %unquote(config_module){config: current_config, version_id: current_version} = state
          ) do
        pid = self()

        schedule_refresh(pid)

        async_fetch = fn ->
          case unquote(fetch_config).(current_version) do
            {:ok, new_config, new_version} -> put_config(pid, new_config, new_version)
            :unchanged -> put_config(pid, current_config, current_version)
            :error -> put_fetch_error(pid)
          end
        end

        # asynchronously update state so that we aren't blocked while waiting for the request to complete
        _ = Task.start(async_fetch)

        {:noreply, state}
      end

      def handle_info(:refresh, :error) do
        pid = self()

        schedule_refresh(pid)

        async_fetch = fn ->
          case unquote(fetch_config).(nil) do
            {:ok, new_config, new_version} -> put_config(pid, new_config, new_version)
            :error -> put_fetch_error(pid)
          end
        end

        _ = Task.start(async_fetch)

        {:noreply, :error}
      end

      # Handle leaked :ssl_closed messages from Hackney.
      # Workaround for this issue: https://github.com/benoitc/hackney/issues/464
      def handle_info({:ssl_closed, _}, state) do
        {:noreply, state}
      end

      @impl true
      def handle_cast({:put_config, new_config, new_version}, _) do
        {:noreply,
         %unquote(config_module){config: new_config, retry_count: 0, version_id: new_version}}
      end

      def handle_cast(:put_fetch_error, state) do
        {:noreply, error_state(state)}
      end

      # Logs fetch failures and returns the appropriate error state.
      @spec error_state(current_state :: t()) :: t()
      defp error_state(:error) do
        _ = Logger.error("config_state_init_fetch_error")
        :error
      end

      defp error_state(%unquote(config_module){
             config: config,
             retry_count: retry_count,
             version_id: version_id
           }) do
        log_message = "config_state_fetch_error retry_count=#{retry_count}"

        _ =
          if log_as_error?(retry_count) do
            Logger.error(log_message)
          else
            Logger.info(log_message)
          end

        %unquote(config_module){
          config: config,
          retry_count: retry_count + 1,
          version_id: version_id
        }
      end

      defp log_as_error?(retry_count) do
        threshold_ms = unquote(fetch_failure_error_threshold_minutes) * 60 * 1000

        retry_count * unquote(refresh_ms) >= threshold_ms
      end
    end
  end
end
