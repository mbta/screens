defmodule Screens.Cache.Engine do
  @moduledoc """
  Behaviour for the engine that gets plugged into a `Screens.Cache.Owner` GenServer.
  """

  @typedoc """
  Settings for the cache. All fields are required.
  """
  @type cache_opts_map :: %{
          name: atom(),
          update_table: update_table_fn,
          update_interval_ms: non_neg_integer,
          update_failure_error_log_threshold_minutes: non_neg_integer
        }

  @type update_table_fn :: (table_version -> update_success | :unchanged | :error)

  @typedoc """
  To be returned by update_table on success.

  new_table_entries must be a tuple or list of tuples, for compatibility with ETS.
  The first element of each tuple is used as the lookup key for that entry.

  :replace causes the table's entire contents to be replaced by the new data.
  :patch only merges the new entries into the existing table contents, overwriting any existing entries with matching keys.
  """
  @type update_success ::
          {:replace, new_table_entries :: tuple | list(tuple), new_version :: table_version}
          | {:patch, updated_table_entries :: tuple | list(tuple)}

  @typedoc """
  Any value representing the current version of the table data.
  This is usually an S3 ETag.

  Always starts out as nil, since we haven't fetched data (and its version metadata) yet.
  """
  @type table_version :: any | nil

  @typedoc """
  "Documentation-only" dummy type representing a module that implements this behaviour.

  Useless to type checkers, but helpful for code readability.
  """
  @type t :: module()

  @doc """
  Returns the name to use for the cache.

  The client will read from the table using this name.
  """
  @callback name() :: atom()

  @doc """
  Returns new data for the cache.
  """
  @callback update_table(table_version) :: update_success | :unchanged | :error

  @doc """
  Returns the number of milliseconds to wait between each `update_table` call.
  """
  @callback update_interval_ms() :: non_neg_integer

  @doc """
  Returns the number of minutes to wait before changing the log level
  for failed `update_table` calls from warning to error.
  """
  @callback update_failure_error_log_threshold_minutes() :: non_neg_integer
end
