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
  @cache_module Screens.Application.config(:screens_by_alert, :cache_module)

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
  def start_link(_opts \\ []) do
    @cache_module.start_link(name: @cache_module)
  end

  @impl true
  def put_data(screen_id, alert_ids) do
    @cache_module.put_data(screen_id, alert_ids)
  end

  @impl true
  def get_screens_by_alert(alert_id) do
    @cache_module.get_screens_by_alert(alert_id)
  end

  @impl true
  def get_screens_last_updated(screen_id) do
    @cache_module.get_screens_last_updated(screen_id)
  end
end
