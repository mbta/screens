defmodule Screens.TriptychPlayer.Cache do
  @moduledoc """
  Functions to read data from a cached copy of the Signs UI config.
  """

  use Screens.Cache.Client, table: :triptych_player

  def fetch_screen_id_for_player(player_name) do
    with_table default: :error do
      case :ets.match(@table, {player_name, :"$1"}) do
        [[screen_id]] -> {:ok, screen_id}
        [] -> :error
      end
    end
  end

  def fetch_player_names_for_screen_id(screen_id) do
    with_table default: :error do
      player_names =
        @table
        # [[name1], [name2], [name3]]
        |> :ets.match({:"$1", screen_id})
        # [name1, name2, name3]
        |> List.flatten()
        # (Just in case)
        |> Enum.uniq()

      case player_names do
        [] -> :error
        l -> {:ok, l}
      end
    end
  end
end
