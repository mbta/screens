defmodule Screens.Override do
  @moduledoc """
  Defines the data structure for overrides, including default values.
  Use the provided `new` function to create Overrides.
  """

  alias __MODULE__

  @map_set_keys [:disabled_screen_ids, :headway_mode_screen_ids]

  defstruct globally_disabled: false,
            disabled_screen_ids: MapSet.new(),
            bus_service: 1,
            green_line_service: 1,
            headway_mode_screen_ids: MapSet.new()

  def new() do
    %Override{}
  end

  @doc """
  Creates a new Override struct from a map.

  ## Example
      iex> Screens.Override.new(%{bus_service: 2, disabled_screen_ids: [1, 2, 2], invalid_key: false})
      %Override{
        bus_service: 2,
        disabled_screen_ids: #MapSet<[1, 2]>,
        globally_disabled: false,
        green_line_service: 1,
        headway_mode_screen_ids: #MapSet<[]>
      }
  """
  def new(map) when is_map(map) do
    struct(Override, enforce_map_set_keys(map))
  end

  defp enforce_map_set_keys(map) do
    map_set_keys = for {k, v} when k in @map_set_keys <- map, into: %{}, do: {k, MapSet.new(v)}
    Map.merge(map, map_set_keys)
  end
end
