defmodule Screens.Config.State.Fetch do
  @moduledoc false

  alias Screens.Config
  @callback fetch_config() :: {:ok, Config.t()} | :error
  @callback get_from_s3() :: {:ok, String.t()} | :error
  @callback put_to_s3(String.t()) :: :ok | :error
end
