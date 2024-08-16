defmodule Screens.Routes.RoutesCache do
  @moduledoc """
  A read-through cache of routes by ID.
  """
  use Nebulex.Cache,
    otp_app: :screens,
    adapter: Application.compile_env(:screens, [__MODULE__, :adapter])

  alias Screens.Routes.Route

  @route_mod Application.compile_env(:screens, :routes_cache_route_mod, Screens.Routes.Route)

  @base_ttl :timer.hours(1)

  @spec by_id(id :: String.t()) :: Route.t() | nil
  def by_id(id) do
    if route = get(id) do
      route
    else
      route = fetch_by_id(id)

      unless is_nil(route), do: put(id, route, ttl: ttl())

      route
    end
  end

  defp fetch_by_id(id) do
    case @route_mod.by_id(id) do
      {:ok, %Route{} = route} -> route
      _ -> nil
    end
  end

  def ttl do
    additional_minutes = :rand.uniform(30)
    @base_ttl + :timer.minutes(additional_minutes)
  end
end
