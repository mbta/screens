defmodule Screens.Config.Behaviour do
  @moduledoc false

  @typedoc """
  Usually a struct or a tuple, but could conceivably be any other Elixir term.
  """
  @type config :: term()

  @typedoc """
  Usually a map or a list, but could conceivably be any other JSON-originated value.
  """
  @type json_config :: term()

  @callback from_json(json_config()) :: config()
  @callback to_json(config()) :: json_config()
end
