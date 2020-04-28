defmodule Screens.Override do
  @moduledoc """
  Defines the data structure for overrides, including default values.
  Use the provided `new` function to create Overrides.
  """

  @type t :: %__MODULE__{
          globally_disabled: boolean(),
          disabled_screen_ids: MapSet.t(pos_integer()),
          bus_service: pos_integer(),
          green_line_service: pos_integer(),
          headway_mode_screen_ids: MapSet.t(pos_integer())
        }

  defstruct globally_disabled: false,
            disabled_screen_ids: MapSet.new(),
            bus_service: 1,
            green_line_service: 1,
            headway_mode_screen_ids: MapSet.new()

  @map_set_keys [:disabled_screen_ids, :headway_mode_screen_ids]

  @spec new :: __MODULE__.t()
  def new, do: %__MODULE__{}

  @doc """
  Creates a new Override struct from a map.

  ## Example
      iex> Screens.Override.from(%{bus_service: 2, disabled_screen_ids: [1, 2, 2], invalid_key: false})
      %Override{
        bus_service: 2,
        disabled_screen_ids: #MapSet<[1, 2]>,
        globally_disabled: false,
        green_line_service: 1,
        headway_mode_screen_ids: #MapSet<[]>
      }
  """
  @spec from(map()) :: __MODULE__.t()
  def from(map) do
    struct(__MODULE__, convert_map_set_keys(map))
  end

  @spec convert_map_set_keys(map()) :: map()
  defp convert_map_set_keys(map) do
    map_set_keys = for {k, v} when k in @map_set_keys <- map, into: %{}, do: {k, MapSet.new(v)}
    Map.merge(map, map_set_keys)
  end
end
