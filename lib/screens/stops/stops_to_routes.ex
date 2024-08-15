defmodule Screens.Stops.StopsToRoutes do
  @moduledoc """
  Cache of stop ids to route ids. Information for stop ids missing from the
  cache is fetched automatically from the V3 API when requested.
  """
  use Nebulex.Cache,
    otp_app: :screens,
    adapter: Application.compile_env(:screens, [__MODULE__, :adapter])

  @route_mod Application.compile_env(:screens, :stops_to_routes_route_mod, Screens.Routes.Route)

  @base_ttl :timer.hours(1)

  @spec stops_to_routes([stop_id :: String.t()]) :: [route_id :: String.t()]
  def stops_to_routes(stop_ids) do
    from_cache = get_all(stop_ids)
    missing_stop_ids = stop_ids -- Map.keys(from_cache)

    from_api =
      if Enum.empty?(missing_stop_ids) do
        %{}
      else
        from_api =
          for stop_id <- missing_stop_ids, into: %{} do
            {:ok, routes} = @route_mod.serving_stop(stop_id)
            route_ids = Enum.map(routes, & &1.id)

            {stop_id, route_ids}
          end

        put_all(from_api, ttl: ttl())

        from_api
      end

    [from_cache, from_api]
    |> Enum.map(&ungroup_values/1)
    |> Enum.concat()
    |> Enum.uniq()
  end

  defp ungroup_values(map) do
    map
    |> Map.values()
    |> List.flatten()
    |> Enum.uniq()
  end

  # Set random TTLs from 1hr to 1.5hrs to alleviate the thundering herd problem
  defp ttl do
    additional_minutes = :rand.uniform(30)
    @base_ttl + :timer.minutes(additional_minutes)
  end
end
