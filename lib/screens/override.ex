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

  @spec new :: __MODULE__.t()
  def new, do: %__MODULE__{}

  @type json_map :: %{
          optional(:globally_disabled) => boolean(),
          optional(:disabled_screen_ids) => list(pos_integer()),
          optional(:bus_service) => pos_integer(),
          optional(:green_line_service) => pos_integer(),
          optional(:headway_mode_screen_ids) => list(pos_integer())
        }

  @doc """
  Creates a new Override struct from parsed JSON.

  ## Example
      iex> Screens.Override.from_json(%{bus_service: 2, disabled_screen_ids: [1, 2, 2], invalid_key: false})
      %Override{
        bus_service: 2,
        disabled_screen_ids: #MapSet<[1, 2]>,
        globally_disabled: false,
        green_line_service: 1,
        headway_mode_screen_ids: #MapSet<[]>
      }
  """
  @spec from_json(json_map()) :: __MODULE__.t()
  def from_json(%{} = override_map) do
    converted =
      override_map
      |> disabled_map_set()
      |> headway_mode_map_set()

    struct(__MODULE__, converted)
  end

  # Converts the `disabled_screen_ids` list to a MapSet, if it exists
  defp disabled_map_set(%{disabled_screen_ids: disabled_screen_ids} = override_map) do
    Map.put(override_map, :disabled_screen_ids, MapSet.new(disabled_screen_ids))
  end

  defp disabled_map_set(%{} = override_map), do: override_map

  # Converts the `disabled_screen_ids` list to a MapSet, if it exists
  defp headway_mode_map_set(%{headway_mode_screen_ids: headway_mode_screen_ids} = override_map) do
    Map.put(override_map, :headway_mode_screen_ids, MapSet.new(headway_mode_screen_ids))
  end

  defp headway_mode_map_set(%{} = override_map), do: override_map
end
