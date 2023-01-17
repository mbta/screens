defmodule Screens.ScreensByAlert do
  @moduledoc """
    Tracks visible alerts by screen.

    The ScreensByAlert server will keep track of all alerts that are currently visible on a screen.

    ### Cache data structure shape:
    ```
      %{
        "screens_by_alert." <> alert_id => list(timestamped_screen_id),
        # metadata to make the "self-refresh" mechanism possible
        "screens_last_updated." <> screen_id => timestamp
      }
    ```
  """

  @behaviour Screens.ScreensByAlert.Behaviour
  @config Application.compile_env(:screens, :screens_by_alert)
  @cache_module @config[:cache_module]

  # Need to define a child_spec since this module does not itself use GenServer or Supervisor,
  # but is a simple wrapper for @cache_module
  @spec child_spec(any()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @impl true
  def start_link(_opts) do
    @cache_module.start_link(
      screens_by_alert_ttl_seconds: @config[:screens_by_alert_ttl_seconds],
      screens_last_updated_ttl_seconds: @config[:screens_last_updated_ttl_seconds],
      screens_ttl_seconds: @config[:screens_ttl_seconds]
    )
  end

  @impl true
  def put_data(screen_id, alert_ids, store_screen_id \\ false) do
    @cache_module.put_data(
      screen_id,
      alert_ids,
      store_screen_id
    )
  end

  @impl true
  def get_screens_by_alert(alert_ids) do
    @cache_module.get_screens_by_alert(alert_ids)
  end

  @impl true
  def get_screens_last_updated(screen_ids) do
    @cache_module.get_screens_last_updated(screen_ids)
  end
end
