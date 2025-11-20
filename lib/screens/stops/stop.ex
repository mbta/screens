defmodule Screens.Stops.Stop do
  @moduledoc false

  require Logger

  alias Screens.RouteType
  alias Screens.V3Api

  defstruct ~w[
    id
    name
    location_type
    parent_station
    child_stops
    connecting_stops
    platform_code
    platform_name
    vehicle_type
  ]a

  @type id :: String.t()
  # A location_type of 1 indicates a parent station complex, whereas 0 indicates a distinct boarding location.
  # A value of 2 designates a station entrance/exit, and 3 indicates a generic node within a station, such as the end of a staircase, elevator, or escalator.
  @type location_type :: 0 | 1 | 2 | 3

  @type t :: %__MODULE__{
          id: id,
          name: String.t(),
          location_type: location_type(),
          parent_station: t() | nil | :unloaded,
          child_stops: [t()] | :unloaded,
          connecting_stops: [t()] | :unloaded,
          platform_code: String.t() | nil,
          platform_name: String.t() | nil,
          vehicle_type: RouteType.t() | nil
        }

  @type params :: %{
          optional(:ids) => [id()],
          optional(:location_types) => [location_type()],
          optional(:route_types) => [RouteType.t()]
        }

  @callback fetch(params()) :: {:ok, [t()]} | :error
  @callback fetch(params(), boolean()) :: {:ok, [t()]} | :error
  def fetch(params, include_related? \\ false, get_json_fn \\ &V3Api.get_json/2) do
    encoded_params =
      params
      |> Enum.flat_map(&encode_param/1)
      |> Map.new()
      |> then(fn params ->
        if include_related? do
          Map.put(
            params,
            "include",
            Enum.join(
              ~w[child_stops connecting_stops parent_station.child_stops parent_station.connecting_stops],
              ","
            )
          )
        else
          params
        end
      end)

    case get_json_fn.("stops", encoded_params) do
      {:ok, response} -> {:ok, V3Api.Parser.parse(response)}
      _ -> :error
    end
  end

  defp encode_param({:ids, ids}), do: [{"filter[id]", Enum.join(ids, ",")}]
  defp encode_param({:location_types, lts}), do: [{"filter[location_type]", Enum.join(lts, ",")}]
  defp encode_param({:route_types, rts}), do: [{"filter[route_type]", Enum.join(rts, ",")}]

  @callback fetch_stop_name(id()) :: String.t() | nil
  def fetch_stop_name(stop_id) do
    case fetch(%{ids: [stop_id]}) do
      {:ok, [%__MODULE__{name: name}]} -> name
      _ -> nil
    end
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
