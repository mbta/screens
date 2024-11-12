defmodule Screens.Stops.Stop do
  @moduledoc false

  require Logger

  alias Screens.RouteType
  alias Screens.Stops.Parser
  alias Screens.V3Api

  defstruct ~w[
    id
    name
    location_type
    parent_station
    child_stops
    platform_code
    platform_name
    vehicle_type
  ]a

  @type id :: String.t()
  @type location_type :: 0 | 1 | 2 | 3

  @type t :: %__MODULE__{
          id: id,
          name: String.t(),
          location_type: location_type(),
          parent_station: t() | nil | :unloaded,
          child_stops: [t()] | :unloaded,
          platform_code: String.t() | nil,
          platform_name: String.t() | nil,
          vehicle_type: RouteType.t() | nil
        }

  @type params :: %{
          optional(:ids) => [id()],
          optional(:location_types) => [location_type()],
          optional(:route_types) => [RouteType.t()]
        }

  @spec fetch(params()) :: {:ok, [t()]} | :error
  @spec fetch(params(), boolean()) :: {:ok, [t()]} | :error
  def fetch(params, include_related? \\ false, get_json_fn \\ &V3Api.get_json/2) do
    encoded_params =
      params
      |> Enum.flat_map(&encode_param/1)
      |> Map.new()
      |> then(fn params ->
        if include_related? do
          Map.put(params, "include", Enum.join(~w[child_stops parent_station.child_stops], ","))
        else
          params
        end
      end)

    case get_json_fn.("stops", encoded_params) do
      {:ok, response} -> {:ok, Parser.parse(response)}
      _ -> :error
    end
  end

  defp encode_param({:ids, ids}), do: [{"filter[id]", Enum.join(ids, ",")}]
  defp encode_param({:location_types, lts}), do: [{"filter[location_type]", Enum.join(lts, ",")}]
  defp encode_param({:route_types, rts}), do: [{"filter[route_type]", Enum.join(rts, ",")}]

  @doc """
  Returns a list of child stops for each given stop ID (in the same order). For stop IDs that are
  already child stops, the list contains only the stop itself. For stop IDs that do not exist, the
  list is empty.
  """
  @callback fetch_child_stops([id()]) :: {:ok, [[t()]]} | :error
  def fetch_child_stops(stop_ids) do
    case fetch(%{ids: stop_ids}, true) do
      {:ok, stops} ->
        stops_by_id = Map.new(stops, fn %__MODULE__{id: id} = stop -> {id, stop} end)

        child_stops =
          stop_ids
          |> Enum.map(&stops_by_id[&1])
          |> Enum.map(fn
            nil -> []
            %__MODULE__{location_type: 0} = stop -> [stop]
            %__MODULE__{child_stops: stops} when is_list(stops) -> stops
          end)

        {:ok, child_stops}

      :error ->
        :error
    end
  end

  @callback fetch_parent_station_name_map() :: {:ok, %{id() => String.t()}} | :error
  def fetch_parent_station_name_map do
    case fetch(%{location_types: [1]}) do
      {:ok, stops} -> {:ok, Map.new(stops, fn %__MODULE__{id: id, name: name} -> {id, name} end)}
      _ -> :error
    end
  end

  @callback fetch_stop_name(id()) :: String.t() | nil
  def fetch_stop_name(stop_id) do
    Screens.Telemetry.span(~w[screens stops stop fetch_stop_name]a, %{stop_id: stop_id}, fn ->
      case fetch(%{ids: [stop_id]}) do
        {:ok, [%__MODULE__{name: name}]} -> name
        _ -> nil
      end
    end)
  end

  @spec fetch_subway_platforms_for_stop(id()) :: [t()]
  def fetch_subway_platforms_for_stop(stop_id) do
    {:ok, [%__MODULE__{child_stops: child_stops}]} = fetch(%{ids: [stop_id]}, true)

    Enum.filter(child_stops, fn
      %__MODULE__{location_type: 0, vehicle_type: vt} when vt in ~w[light_rail subway]a -> true
      _ -> false
    end)
  end
end
