defmodule Screens.Config.State.Fetch do
  @moduledoc false

  alias Screens.ConfigCache.State.Fetch

  @callback get_config(Fetch.version_id()) ::
              {:ok, String.t(), Fetch.version_id()} | :unchanged | :error
  @callback put_config(String.t()) :: :ok | :error
end
