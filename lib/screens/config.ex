defmodule Screens.Config do
  @moduledoc false

  alias Screens.Config.{Devops, Screen}

  @type t :: %__MODULE__{
          screens: %{
            screen_id => Screen.t()
          },
          devops: Devops.t()
        }

  @type screen_id :: String.t()

  @enforce_keys [:screens]
  defstruct screens: nil,
            devops: Devops.from_json(:default)

  use Screens.Config.Struct, children: [screens: {:map, Screen}, devops: Devops]

  @spec schedule_refresh_for_screen_ids(t(), list(String.t())) :: t()
  def schedule_refresh_for_screen_ids(config, screen_ids) do
    %__MODULE__{screens: current_screens, devops: devops} = config

    now = DateTime.utc_now()

    new_screens =
      current_screens
      |> Enum.map(fn {screen_id, screen_config} ->
        new_screen_config =
          if screen_id in screen_ids do
            Screen.schedule_refresh_at_time(screen_config, now)
          else
            screen_config
          end

        {screen_id, new_screen_config}
      end)
      |> Enum.into(%{})

    %__MODULE__{screens: new_screens, devops: devops}
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
