defmodule Screens.Routes.Route do
  @moduledoc false

  alias Screens.V3Api

  defstruct id: nil,
            short_name: nil,
            long_name: nil,
            direction_destinations: nil,
            type: nil

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id,
          short_name: String.t(),
          long_name: String.t(),
          direction_destinations: list(String.t()),
          type: Screens.RouteType.t()
        }

  def by_id(route_id) do
    case V3Api.get_json("routes/" <> route_id) do
      {:ok, %{"data" => data}} -> {:ok, Screens.Routes.Parser.parse_route(data)}
      _ -> :error
    end
  end

  def fetch(opts \\ [], get_json_fn \\ &V3Api.get_json/2) do
    params =
      opts
      |> Enum.flat_map(&format_query_param/1)
      |> Enum.into(%{})

    case get_json_fn.("routes/", params) do
      {:ok, %{"data" => data}} -> {:ok, Enum.map(data, &Screens.Routes.Parser.parse_route/1)}
      _ -> :error
    end
  end

  @doc """
  Fetches IDs and active status of routes that serve the given stop. `today` is used to determine whether
  each route is actively running on the current day.
  """
  @spec fetch_simplified_routes_at_stop(String.t()) ::
          {:ok, list(%{route_id: id(), active?: boolean()})} | :error
  def fetch_simplified_routes_at_stop(
        stop_id,
        now \\ DateTime.utc_now(),
        get_json_fn \\ &V3Api.get_json/2
      ) do
    with {:ok, all_route_ids} <- fetch_all_route_ids(stop_id, get_json_fn),
         {:ok, active_route_ids} <- fetch_active_route_ids(stop_id, now, get_json_fn) do
      active_set = MapSet.new(active_route_ids)

      routes_at_stop =
        Enum.map(all_route_ids, &%{route_id: &1, active?: MapSet.member?(active_set, &1)})

      {:ok, routes_at_stop}
    else
      :error -> :error
    end
  end

  @doc """
  Fetches routes that serve the given stop. `now` is used to determine whether
  each route is actively running on the current day.
  """
  @spec fetch_routes_by_stop(String.t()) ::
          {:ok, list(%{route_id: id(), active?: boolean()})} | :error
  def fetch_routes_by_stop(
        stop_id,
        now \\ DateTime.utc_now(),
        type_filters \\ [],
        get_json_fn \\ &V3Api.get_json/2,
        fetch_routes_fn \\ &fetch_routes/3
      ) do
    with {:ok, routes} <- fetch_routes_fn.(stop_id, get_json_fn, type_filters),
         {:ok, active_route_ids} <- fetch_active_route_ids(stop_id, now, get_json_fn) do
      active_set = MapSet.new(active_route_ids)

      routes_at_stop =
        Enum.map(
          routes,
          &(&1
            |> Map.from_struct()
            |> Map.put(:active?, MapSet.member?(active_set, &1.id))
            |> Map.put(:route_id, &1.id)
            |> Map.delete(:id))
        )

      {:ok, routes_at_stop}
    else
      :error -> :error
    end
  end

  defp format_query_param({:stop_ids, stop_ids}) when is_list(stop_ids) do
    [{"filter[stop]", Enum.join(stop_ids, ",")}]
  end

  defp format_query_param({:stop_id, stop_id}) when is_binary(stop_id) do
    format_query_param({:stop_ids, [stop_id]})
  end

  defp format_query_param({:date, %Date{} = d}) do
    [{"filter[date]", Date.to_iso8601(d)}]
  end

  defp format_query_param({:date, %DateTime{} = dt}) do
    format_query_param({:date, DateTime.to_date(dt)})
  end

  defp format_query_param({:route_types, route_types}) when is_list(route_types) do
    [{"filter[type]", Enum.join(route_types, ",")}]
  end

  defp format_query_param(_), do: []

  defp fetch_all_route_ids(stop_id, get_json_fn) do
    case fetch([stop_id: stop_id], get_json_fn) do
      {:ok, routes} -> {:ok, Enum.map(routes, & &1.id)}
      :error -> :error
    end
  end

  defp fetch_routes(stop_id, get_json_fn, type_filters) do
    case fetch([stop_id: stop_id, route_types: type_filters], get_json_fn) do
      {:ok, routes} -> {:ok, routes}
      :error -> :error
    end
  end

  defp fetch_active_route_ids(stop_id, now, get_json_fn) do
    case fetch([stop_id: stop_id, date: now], get_json_fn) do
      {:ok, routes} -> {:ok, Enum.map(routes, & &1.id)}
      :error -> :error
    end
  end
end
