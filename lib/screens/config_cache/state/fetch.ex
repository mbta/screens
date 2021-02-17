defmodule Screens.ConfigCache.State.Fetch do
  @moduledoc false

  @type version_id :: String.t() | nil

  @callback fetch_config(version_id) :: {:ok, term(), version_id} | :unchanged | :error
end
