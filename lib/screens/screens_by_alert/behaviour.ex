defmodule Screens.ScreensByAlert.Behaviour do
  @moduledoc """
  Behavior for accessing the cache that holds screens by alert.

  - `start_link()` is called to start the backend by the supervisor.
  - `put_data(screen_id, list(alert_id))` inserts the list of alert_ids visible on a given screen_id
    to the cache.
  - `get_screens_by_alert(alert_id)` returns all screen_ids that are currently displaying the given alert_id.
  - `get_screens_last_updated(screen_id)` returns the timestamp that represents the last time a given screen_id was updated.

  """
  @type screen_id :: String.t()
  @type alert_id :: String.t()
  @type timestamp :: integer()
  @type timestamped_screen_id :: {screen_id, timestamp}

  @callback start_link :: {:ok, pid}
  @callback put_data(screen_id(), list(alert_id())) :: :ok
  @callback get_screens_by_alert(alert_id()) :: list(timestamped_screen_id())
  @callback get_screens_last_updated(screen_id()) :: timestamp()
end
