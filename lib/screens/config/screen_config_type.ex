defmodule Screens.Config.ScreenConfigType do
  @moduledoc """
  Custom `Ecto.Type` for screen configuration payloads.

  This type stores config data as a map in the database while supporting
  `%ScreensConfig.Screen{}` structs at the application boundary.

  On load, it hydrates persisted maps into `%ScreensConfig.Screen{}`.
  """

  @behaviour Ecto.Type

  alias ScreensConfig.Screen

  @impl true
  def type, do: :map

  @impl true
  def cast(%Screen{} = screen), do: {:ok, screen}

  def cast(%{} = map), do: {:ok, Screen.from_json(map)}

  def cast(_), do: :error

  @impl true
  def load(config) when is_map(config) do
    case Screen.from_json(config) do
      %Screen{} = screen -> {:ok, screen}
      nil -> {:ok, config}
    end
  end

  def load(_), do: :error

  @impl true
  def dump(%Screen{} = screen), do: {:ok, Screen.to_json(screen)}

  def dump(_), do: :error

  @impl true
  def embed_as(_format), do: :self

  @impl true
  def equal?(left, right), do: left == right
end
