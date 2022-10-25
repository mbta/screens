defmodule Screens.ScreensByAlert.Behaviour do
  @moduledoc """
  Behavior for accessing the cache that holds screens by alert.

  - `start_link(opts)` is called to start the backend by the supervisor.
  - `put_data(screen_id, list(alert_id))` inserts the list of alert_ids visible on a given screen_id
    to the cache.
  - `get_screens_by_alert(alert_ids)` returns a map associating each requested alert_id with the screen IDs that are currently displaying it.
  - `get_screens_last_updated(screen_ids)` returns a map associating each requested screen_id with its last-updated Unix timestamp.

  """
  @type screen_id :: String.t()
  @type alert_id :: String.t()
  @type timestamp :: integer()
  @type timestamped_screen_id :: {screen_id, timestamp}

  @doc """
  Starts the process that interfaces with the screens-by-alert cache.
  """
  @callback start_link(Keyword.t()) :: {:ok, pid()}

  @doc """
  Takes a screen ID and a list of alert IDs as parameters. With these, it will get an existing object
  or create a new object in the cache using each alert_id. The key of each object is the `alert_id`, the value
  is the list of `screen_id`s.
  """
  @callback put_data(screen_id(), list(alert_id())) :: :ok

  @doc """
  Given a list of 0 or more alert IDs, returns a mapping from each requested alert ID
  to the list of screens currently showing it.

  If a cache item is missing for some alert, its screens-list value will default to [].
  """
  @callback get_screens_by_alert(list(alert_id())) :: %{alert_id() => list(screen_id())}

  @doc """
  Given a list of 0 or more screen IDs, returns a mapping from each requested screen ID
  to its last-updated Unix timestamp.

  If a cache item is missing for some screen, its timestamp value will default to 0.
  """
  @callback get_screens_last_updated(list(screen_id())) :: %{screen_id() => timestamp()}
end
