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
          config_by_screen_id: %{String.t() => screen_id_config()}
        }

  @type screen_id_config :: %{
          psa_list: {String.t(), list(String.t())},
          audio_psa: {audio_type(), String.t()} | nil
        }

  @type audio_type :: :plaintext | :ssml

  defstruct api_version: 1,
            globally_disabled: false,
            disabled_screen_ids: MapSet.new(),
            bus_service: 1,
            green_line_service: 1,
            headway_mode_screen_ids: MapSet.new(),
            config_by_screen_id: %{}

  @spec new :: __MODULE__.t()
  def new, do: %__MODULE__{}

  @type json_map :: %{
          optional(:api_version) => pos_integer(),
          optional(:globally_disabled) => boolean(),
          optional(:disabled_screen_ids) => list(pos_integer()),
          optional(:bus_service) => pos_integer(),
          optional(:green_line_service) => pos_integer(),
          optional(:headway_mode_screen_ids) => list(pos_integer()),
          optional(:config_by_screen_id) => %{String.t() => screen_id_config_json()}
        }

  @type screen_id_config_json :: %{
          # psa_list: [String.t(), list(String.t())]
          psa_list: list(),
          # audio_psa: ["plaintext" | "ssml", String.t()]
          audio_psa: list() | nil
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
      |> config_by_screen_id_map()

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

  # Converts the keyword-list-like config_by_screen_id to a map, if it exists
  defp config_by_screen_id_map(%{config_by_screen_id: config_by_screen_id} = override_map) do
    config_map =
      for [screen_id, config] <- config_by_screen_id,
          into: %{},
          do: {screen_id, screen_config_map(config)}

    Map.put(override_map, :config_by_screen_id, config_map)
  end

  defp config_by_screen_id_map(%{} = override_map), do: override_map

  defp screen_config_map(%{psa_list: [psa_type, psa_list], audio_psa: audio_psa}) do
    %{
      psa_list: {psa_type, psa_list},
      audio_psa: audio_psa_tuple(audio_psa)
    }
  end

  defp audio_psa_tuple([audio_type, text]) do
    {audio_type_atom(audio_type), text}
  end

  defp audio_psa_tuple(nil), do: nil

  defp audio_type_atom("plaintext"), do: :plaintext
  defp audio_type_atom("ssml"), do: :ssml
end
