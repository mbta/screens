defmodule Screens.V2.WidgetInstance.SubwayStatus.Serialize.Endpoints do
  @moduledoc """
  Shared functions for determining the beginning and end stops of an alert.
  Future opportunity to use this for other alerts
  """

  alias Screens.Alerts.InformedEntity
  alias Screens.Routes.Route
  alias Screens.Stops.Subway

  @type endpoints :: {{String.t(), String.t()}, {String.t(), String.t()}}

  @spec get([InformedEntity.t()], Route.id()) :: Subway.station()
  def get(informed_entities, route_id) do
    case informed_entities
         |> Subway.affected_stops_on_route(route_id)
         |> Enum.reject(&is_nil(&1)) do
      [] ->
        nil

      stop_lists ->
        {{min_full_name, min_abbreviated_name}, {max_full_name, max_abbreviated_name}} =
          to_endpoints(stop_lists)

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
  defp to_endpoints(nil), do: nil

  defp to_endpoints(stop_lists) do
    # TODO: Don't hardcode GL direction names and handle other way around
    direction_names = %{forward: "Westbound", backward: "Eastbound"}

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

  @spec tuple_for_direction_name(String.t()) :: {String.t(), String.t()}
  defp tuple_for_direction_name(direction_name), do: {direction_name <> " Stops", direction_name}

  # Traverses an UnrootedPolytree of stops using the `previous` field
  # on each node in order to traverse backwards to the first affected
  # stop. See `traverse_from_nodes/3` for more info.
  defp first_stops(stop_tree) do
    stop_tree
    |> traverse_from_nodes(stop_tree.starting_nodes, & &1.previous)
    |> Enum.map(& &1.value)
  end

  # Traverses an UnrootedPolytree of stops using the `next` field on
  # each node in order to traverse forwards to the last affected
  # stop. See `traverse_from_nodes/3` for more info.
  @spec last_stops(UnrootedPolytree.t()) :: []
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
  defp traverse_from_nodes(unrooted_polytree, node_ids, traversal_fun) do
    node_ids
    |> Enum.flat_map(&(unrooted_polytree |> traverse_from_node(&1, traversal_fun)))
    |> Enum.uniq_by(& &1.id)
  end

  # Helper function used by `traverse_from_nodes/3` to traverse an
  # UnrootedPolytree from a single node.
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
end
