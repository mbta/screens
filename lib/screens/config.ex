defmodule Screens.Config do
  alias Screens.Config.Screen

  @type t :: %{
          screen_id => Screen.t()
        }

  @type screen_id :: String.t()

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    Enum.into(json, %{}, fn {screen_id, screen_config} ->
      {screen_id, Screen.from_json(screen_config)}
    end)
  end

  def from_json(:default) do
    %{}
  end

  @spec to_json(t()) :: map()
  def to_json(config) do
    Enum.into(config, %{}, fn {screen_id, screen_config} ->
      {screen_id, Screen.to_json(screen_config)}
    end)
  end
end
