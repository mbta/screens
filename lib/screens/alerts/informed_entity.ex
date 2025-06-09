defmodule Screens.Alerts.InformedEntity do
  @moduledoc """
  Functions to query alert informed entities.
  """

  alias Screens.Trips.Trip
  alias Screens.Routes.Route
  alias Screens.Alerts.Alert

  @type t :: Alert.informed_entity()

  @spec whole_route?(t()) :: boolean
  def whole_route?(ie) do
    match?(
      %{route: route_id, direction_id: nil, stop: nil}
      when not is_nil(route_id),
      ie
    )
  end

  @spec whole_direction?(t()) :: boolean
  def whole_direction?(ie) do
    match?(
      %{route: route_id, direction_id: direction_id, stop: nil}
      when not is_nil(route_id) and not is_nil(direction_id),
      ie
    )
  end

  @spec parent_station?(t()) :: boolean
  def parent_station?(ie) do
    match?(%{stop: "place-" <> _}, ie)
  end

  @spec all_routes_represented?([Route.id()], Trip.direction() | :both | nil, [t()]) :: boolean()
  def all_routes_represented?(route_ids, direction_id, informed_entities) do
    Enum.all?(route_ids, fn route_id ->
      Enum.any?(informed_entities, fn entity ->
        entity_matches?(entity, route_id, direction_id)
      end)
    end)
  end

  defp entity_matches?(
         %{route: entity_route, direction_id: entity_direction},
         route_id,
         direction_id
       )
       when entity_route.id == route_id do
    case entity_direction do
      ^direction_id -> true
      nil -> true
      _ -> false
    end
  end

  defp entity_matches?(_, _, _), do: false
end
