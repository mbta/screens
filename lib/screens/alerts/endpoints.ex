defmodule Screens.Alerts.Endpoints do
  @moduledoc """
  Shared functions for determining the beginning and end stops of an alert.
  """

  alias Screens.Alerts.InformedEntity
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.Stops.Subway
  alias Screens.V2.WidgetInstance.SubwayStatus.Serialize.Utils

  @typep direction_id_t() :: 0 | 1
  @typep direction_name_map_t() :: %{forward: String.t(), backward: String.t()}
  @type endpoints_t :: %{:abbrev => String.t(), :full => String.t()}
  @typep traversal_fun_t() :: (UnrootedPolytree.Edges.t() -> [UnrootedPolytree.Node.t()])

  @spec get([InformedEntity.t()], Route.id()) :: endpoints_t() | nil
  def get(informed_entities, route_id) do
    case informed_entities
         |> Subway.affected_stops_on_route(route_id)
         |> Enum.reject(&is_nil(&1)) do
      [] ->
        nil

      stop_lists ->
        {{min_full_name, min_abbreviated_name}, {max_full_name, max_abbreviated_name}} =
          to_endpoints(
            stop_lists,
            direction_names_for_route(route_id, affected_direction_id(informed_entities))
          )

        if min_full_name == max_full_name and min_abbreviated_name == max_abbreviated_name do
          %{
            full: "#{min_full_name}",
            abbrev: "#{min_abbreviated_name}"
          }
        else
          %{
            full: "#{min_full_name} ↔ #{max_full_name}",
            abbrev: "#{min_abbreviated_name} ↔ #{max_abbreviated_name}"
          }
        end
    end
  end

  # Given a list of lists of affected stops, converts them to a single
  # endpoint stop-range. If there is an unambiguous first stop in that
  # range, then it returns that as the first stop; ditto for the last
  # stop. Otherwise, in either case, it returns the direction name,
  # e.g. "Westbound Stops".
  #
  # It does this by constructing an UnrootedPolytree out of the
  # affected stop lists, and traversing the tree in both
  # directions. If it gets to one end of the tree and has only one
  # unique stop, then that means that stop is the unambiguous endpoint
  # in that direction - if there are multiple, then there is no
  # unambiguous endpoint in that direction.
  @spec to_endpoints([[Subway.station()]], direction_name_map_t()) ::
          {Subway.station_names(), Subway.station_names()}
  defp to_endpoints(stop_lists, direction_names) do
    stop_tree =
      stop_lists
      |> Enum.map(fn stops -> stops |> Enum.map(&{elem(&1, 0), elem(&1, 1)}) end)
      |> UnrootedPolytree.from_lists()

    %{
      first_stops: stop_tree |> first_stops(),
      last_stops: stop_tree |> last_stops()
    }
    |> case do
      %{first_stops: [first_stop], last_stops: [last_stop]} ->
        {first_stop, last_stop}

      %{first_stops: [first_stop], last_stops: _last_stops} ->
        {first_stop, tuple_for_direction_name(direction_names.forward)}

      %{first_stops: _first_stops, last_stops: [last_stop]} ->
        {tuple_for_direction_name(direction_names.backward), last_stop}

      %{first_stops: _first_stops, last_stops: _last_stops} ->
        {
          tuple_for_direction_name(direction_names.backward),
          tuple_for_direction_name(direction_names.forward)
        }
    end
  end

  @spec direction_names_for_route(Route.id(), direction_id_t()) :: direction_name_map_t()
  defp direction_names_for_route(route_id, direction_id) do
    Utils.route_directions()
    |> Map.get(route_id)
    |> to_forward_backward_direction_map(direction_id)
  end

  # Given an alert, returns the affected direction ID, if there is one
  # provided in the alert. If there are multiple, returns one at
  # random. If there aren't any, defaults to 0.
  @spec affected_direction_id([InformedEntity.t()]) :: direction_id_t()
  defp affected_direction_id(entities) do
    entities
    |> Enum.reject(&Kernel.is_nil/1)
    |> List.first(0)
    |> Map.get("direction_id", 0)
  end

  # Given a direction, constructs full and abbreviated naming
  @spec tuple_for_direction_name(String.t()) :: Subway.station_names()
  defp tuple_for_direction_name(direction_name), do: {direction_name <> " Stops", direction_name}

  # Traverses an UnrootedPolytree of stops using the `previous` field
  # on each node in order to traverse backwards to the first affected
  # stop. See `traverse_from_nodes/3` for more info.
  @spec first_stops(UnrootedPolytree.t()) :: [Subway.station_names()]
  defp first_stops(stop_tree) do
    stop_tree
    |> traverse_from_nodes(stop_tree.starting_nodes, & &1.previous)
    |> Enum.map(& &1.value)
  end

  # Traverses an UnrootedPolytree of stops using the `next` field on
  # each node in order to traverse forwards to the last affected
  # stop. See `traverse_from_nodes/3` for more info.
  @spec last_stops(UnrootedPolytree.t()) :: [Subway.station_names()]
  defp last_stops(stop_tree) do
    stop_tree
    |> traverse_from_nodes(stop_tree.starting_nodes, & &1.next)
    |> Enum.map(& &1.value)
  end

  # Traverses an UnrootedPolytree using the provided `traversal_fun`
  # to search recursively through the tree until it reaches a node
  # with no edges.
  #
  # It de-duplicates identical node ID's, so even if there are two
  # branches, if they arrive at the same stop in the end, then it only
  # returns that node once.
  @spec traverse_from_nodes(UnrootedPolytree.t(), [Stop.id()], traversal_fun_t()) ::
          [UnrootedPolytree.Node.t()]
  defp traverse_from_nodes(unrooted_polytree, node_ids, traversal_fun) do
    node_ids
    |> Enum.flat_map(&(unrooted_polytree |> traverse_from_node(&1, traversal_fun)))
    |> Enum.uniq_by(& &1.id)
  end

  # Helper function used by `traverse_from_nodes/3` to traverse an
  # UnrootedPolytree from a single node.
  @spec traverse_from_node(UnrootedPolytree.t(), Stop.id(), traversal_fun_t()) ::
          [UnrootedPolytree.Node.t()]
  defp traverse_from_node(unrooted_polytree, node_id, traversal_fun) do
    unrooted_polytree
    |> UnrootedPolytree.edges_for_id(node_id)
    |> Kernel.then(traversal_fun)
    |> case do
      [] ->
        unrooted_polytree
        |> UnrootedPolytree.node_for_id(node_id)
        |> case do
          {:ok, node} -> [node]
          _ -> []
        end

      edges ->
        unrooted_polytree |> traverse_from_nodes(edges, traversal_fun)
    end
  end

  # Converts a route's direction map into an
  # orientation-aware %{forward: _, backward: _} direction map, based
  # on the direction ID provided.
  @spec to_forward_backward_direction_map([String.t()], direction_id_t()) ::
          direction_name_map_t()
  defp to_forward_backward_direction_map(direction_names, 0),
    do: %{forward: Enum.at(direction_names, 0), backward: Enum.at(direction_names, 1)}

  defp to_forward_backward_direction_map(direction_names, 1),
    do: %{forward: Enum.at(direction_names, 1), backward: Enum.at(direction_names, 0)}
end
