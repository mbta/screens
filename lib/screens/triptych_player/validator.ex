defmodule Screens.TriptychPlayer.Validator do
  @moduledoc false

  @doc """
  Determines whether a term is a valid player name -> screen ID mapping.
  """
  @spec validate(term()) :: :ok | {:error, reason :: String.t()}
  def validate(mapping) do
    with :ok <- validate_map(mapping),
         :ok <- validate_string_keys(mapping) do
      validate_screen_id_values(mapping)
    end
  end

  defp validate_map(mapping) when is_map(mapping), do: :ok
  defp validate_map(_), do: {:error, "Not a map"}

  defp validate_string_keys(mapping) do
    invalid_keys =
      mapping
      |> Map.keys()
      |> Enum.reject(&is_binary/1)

    case invalid_keys do
      [] -> :ok
      keys -> {:error, "Mapping contains non-string keys: #{inspect(keys)}"}
    end
  end

  defp validate_screen_id_values(mapping) do
    mapped_screen_ids =
      mapping
      |> Map.values()
      |> MapSet.new()

    all_triptych_screen_ids =
      MapSet.new(
        Screens.Config.State.screen_ids(&match?({_screen_id, %{app_id: :triptych_v2}}, &1))
      )

    if MapSet.subset?(mapped_screen_ids, all_triptych_screen_ids) do
      :ok
    else
      unrecognized_ids =
        mapped_screen_ids
        |> MapSet.difference(all_triptych_screen_ids)
        |> Enum.sort()

      {:error,
       "Mapping contains unrecognized triptych screen IDs: #{inspect(unrecognized_ids)}.\n\n" <>
         "Make sure all relevant screens have been configured as triptychs before linking them to triptych player names."}
    end
  end
end
