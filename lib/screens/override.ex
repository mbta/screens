defmodule Screens.Override do
  @moduledoc """
  Defines the data structure for overrides, including default values.
  Use the provided `new` function to create Overrides.
  """

  @type t :: %__MODULE__{
          api_version: pos_integer(),
          globally_disabled: boolean(),
          disabled_screen_ids: MapSet.t(pos_integer()),
          bus_service: pos_integer(),
          green_line_service: pos_integer(),
          headway_mode_screen_ids: MapSet.t(pos_integer()),
          psa_lists_by_screen_id: %{String.t() => {String.t(), list(String.t())}}
        }

  defstruct api_version: 1,
            globally_disabled: false,
            disabled_screen_ids: MapSet.new(),
            bus_service: 1,
            green_line_service: 1,
            headway_mode_screen_ids: MapSet.new(),
            psa_lists_by_screen_id: %{}

  @spec new :: __MODULE__.t()
  def new, do: %__MODULE__{}

  @type json_map :: %{
          optional(:api_version) => pos_integer(),
          optional(:globally_disabled) => boolean(),
          optional(:disabled_screen_ids) => list(pos_integer()),
          optional(:bus_service) => pos_integer(),
          optional(:green_line_service) => pos_integer(),
          optional(:headway_mode_screen_ids) => list(pos_integer()),
          optional(:psa_lists_by_screen_id) => %{String.t() => {String.t(), list(String.t())}}
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
        headway_mode_screen_ids: #MapSet<[]>,
        ... more values added after this comment was written
      }
  """
  @spec from_json(json_map()) :: __MODULE__.t()
  def from_json(%{} = override_map) do
    converted =
      override_map
      |> disabled_map_set()
      |> headway_mode_map_set()
      |> psa_lists_map()

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

  # Converts the keyword-list-like psa_lists_by_screen_id to a map, if it exists
  defp psa_lists_map(%{psa_lists_by_screen_id: psa_lists_by_screen_id} = override_map) do
    psa_lists_map =
      for [screen_id, [psa_type, psa_list]] <- psa_lists_by_screen_id,
          into: %{},
          do: {screen_id, {psa_type, psa_list}}

    Map.put(override_map, :psa_lists_by_screen_id, psa_lists_map)
  end

  defp psa_lists_map(%{} = override_map), do: override_map
end
