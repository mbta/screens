defmodule Screens.HeadsignMatchers do
  @moduledoc false

  alias Screens.Stops.Stop
  alias ScreensConfig.Screen

  @type t :: %{
          informed: MapSet.t(Stop.id()),
          not_informed: MapSet.t(Stop.id()),
          alert_headsign: headsign(),
          headway_headsign: headsign()
        }

  @typedoc """
  A headsign indicating the direction a vehicle is headed in.

  In rare cases, an adjective form is used, e.g. "westbound".
  For these cases, the headsign is wrapped in a tagged `{:adj, headsign}` tuple
  to indicate that the headsign may need to be rendered differently.

  See the `*_headsign_matchers` values in config.exs for examples.
  """
  @type headsign :: String.t() | {:adj, String.t()}

  to_set = fn
    nil -> MapSet.new([])
    id when is_binary(id) -> MapSet.new([id])
    ids when is_list(ids) -> MapSet.new(ids)
    %MapSet{} = set -> set
  end

  setify_config = fn matchers ->
    matchers
    |> Enum.map(fn {stop_id, matchers} ->
      {stop_id,
       Enum.map(matchers, fn %{informed: informed, not_informed: not_informed} = t ->
         %{t | informed: to_set.(informed), not_informed: to_set.(not_informed)}
       end)}
    end)
    |> Map.new()
  end

  @dup_matchers :screens
                |> Application.compile_env!(:dup_alert_headsign_matchers)
                |> setify_config.()
  @prefare_matchers :screens
                    |> Application.compile_env!(:prefare_alert_headsign_matchers)
                    |> setify_config.()

  @callback get(Screen.app_id(), Stop.id()) :: [t()]
  def get(:dup_v2, stop_id), do: Map.get(@dup_matchers, stop_id, [])
  def get(:pre_fare_v2, stop_id), do: Map.get(@prefare_matchers, stop_id, [])
end
