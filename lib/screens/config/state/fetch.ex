defmodule Screens.Config.State.Fetch do
  @moduledoc false

  alias Screens.ConfigCache.State.Fetch

  @callback get_from_s3(Fetch.version_id()) ::
              {:ok, String.t(), Fetch.version_id()} | :unchanged | :error
  @callback put_to_s3(String.t()) :: :ok | :error
end
