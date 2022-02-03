defmodule Screens.Stops.Stop do
  @moduledoc false

  alias Screens.Routes
  alias Screens.Stops.StationsWithRoutesAgent
  alias Screens.V3Api

  defstruct id: nil,
            name: nil

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id,
          name: String.t()
        }

  def fetch_parent_station_name_map(get_json_fn \\ &V3Api.get_json/2) do
    case get_json_fn.("stops", %{
           "filter[location_type]" => 1
         }) do
      {:ok, %{"data" => data}} ->
        parsed =
          data
          |> Enum.map(fn %{"id" => id, "attributes" => %{"name" => name}} -> {id, name} end)
          |> Enum.into(%{})

        {:ok, parsed}

      _ ->
        :error
    end
  end

  def fetch_routes_serving_stop(station_id, headers \\ [], get_json_fn \\ &V3Api.get_json/5) do
    case get_json_fn.(
           "routes",
           %{
             "filter[stop]" => station_id
           },
           headers,
           [],
           true
         ) do
      {:ok, %{"data" => data}, headers} ->
        date =
          headers
          |> Enum.into(%{})
          |> Map.get("last-modified")

        routes =
          data
          |> Enum.map(fn route -> Routes.Parser.parse_route(route) end)

        StationsWithRoutesAgent.put(station_id, routes, date)

        {:ok, routes}

      :not_modified ->
        :not_modified

      _ ->
        :error
    end
  end

  def create_station_with_routes_map(station_id) do
    case StationsWithRoutesAgent.get(station_id) do
      {routes, date} ->
        case fetch_routes_serving_stop(station_id, [{"if-modified-since", date}]) do
          {:ok, new_routes} -> new_routes
          :not_modified -> routes
        end

      nil ->
        case fetch_routes_serving_stop(station_id) do
          {:ok, new_routes} -> new_routes
        end
    end
  end
end
