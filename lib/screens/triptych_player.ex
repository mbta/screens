defmodule Screens.TriptychPlayer do
  @moduledoc """
  Provides access to a mapping from triptych player name
  (a unique ID for an individual pane of a triptych trio, provided by OFM)
  to screen ID
  (our ID for the collective triptych screen comprising 3 panes).

  The mapping is cached in an ETS table controlled by a GenServer
  which checks for updates to the source JSON file every 15 seconds.
  """

  alias Screens.TriptychPlayer.Cache
  alias Screens.TriptychPlayer.Validator

  defdelegate fetch_screen_id_for_player(player_name), to: Cache

  defdelegate fetch_player_names_for_screen_id(player_name), to: Cache

  defdelegate validate(mapping), to: Validator
end
