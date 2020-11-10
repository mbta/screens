defmodule Screens.Config do
  @moduledoc false

  alias Screens.Config.{Devops, Screen}
  alias Screens.Util

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

  @spec from_json(map()) :: t()
  def from_json(%{} = json) do
    struct_map =
      json
      |> Map.take(Util.struct_keys(__MODULE__))
      |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), value_from_json(k, v)} end)

    struct!(__MODULE__, struct_map)
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = t) do
    t
    |> Map.from_struct()
    |> Enum.into(%{}, fn {k, v} -> {k, value_to_json(k, v)} end)
  end

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

  defp value_from_json("screens", screens) do
    Enum.into(screens, %{}, fn {screen_id, screen_config} ->
      {screen_id, Screen.from_json(screen_config)}
    end)
  end

  defp value_from_json("devops", devops) do
    Devops.from_json(devops)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(:screens, screens) do
    Enum.into(screens, %{}, fn {screen_id, screen_config} ->
      {screen_id, Screen.to_json(screen_config)}
    end)
  end

  defp value_to_json(:devops, devops) do
    Devops.to_json(devops)
  end

  defp value_to_json(_, value), do: value
end
