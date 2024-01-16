defmodule Screens.PendingConfig do
  @moduledoc false
  alias ScreensConfig.Screen

  @type t :: %__MODULE__{
          screens: %{
            Screens.Config.screen_id() => Screen.t()
          }
        }

  @enforce_keys [:screens]
  defstruct @enforce_keys

  use ScreensConfig.Struct, children: [screens: {:map, Screen}]

  defp value_from_json(_, value), do: value
  defp value_to_json(_, value), do: value
end
