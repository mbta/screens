defmodule Screens.Config do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Util

  @type t :: %__MODULE__{
          screens: %{
            screen_id => Screen.t()
          }
        }

  @type screen_id :: String.t()

  @enforce_keys [:screens]
  defstruct @enforce_keys

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

  defp value_from_json("screens", screens) do
    Enum.into(screens, %{}, fn {screen_id, screen_config} ->
      {screen_id, Screen.from_json(screen_config)}
    end)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(:screens, screens) do
    Enum.into(screens, %{}, fn {screen_id, screen_config} ->
      {screen_id, Screen.to_json(screen_config)}
    end)
  end

  defp value_to_json(_, value), do: value
end
