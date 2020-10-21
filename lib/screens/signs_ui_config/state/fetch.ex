defmodule Screens.SignsUiConfig.State.Fetch do
  @moduledoc false

  @callback fetch_config() :: {:ok, Screens.SignsUiConfig.State.config()} | :error
end
