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
  @cache_module Application.compile_env!(:screens, [:screens_by_alert, :cache_module])

  # Need to define a child_spec since this module does not itself use GenServer or Supervisor,
  # but is a simple wrapper for @cache_module
  @spec child_spec(any()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  defdelegate start_link(opts), to: @cache_module
  defdelegate put_data(screen_id, alert_ids), to: @cache_module
  defdelegate get_screens_by_alert(alert_ids), to: @cache_module
  defdelegate get_screens_last_updated(screen_ids), to: @cache_module
end
