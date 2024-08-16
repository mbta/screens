defmodule Screens.Routes.RoutesCache do
  @moduledoc """
  A read-through cache of routes by ID.
  """
  use Nebulex.Cache,
    otp_app: :screens,
    adapter: Nebulex.Adapters.Local

  alias Screens.Routes.Route

  @base_ttl :timer.hours(1)

  @spec by_id(id :: String.t()) :: Route.t() | nil
  def by_id(id) do
    if route = get(id) do
      route
    else
      case Route.by_id(id) do
        {:ok, %Route{} = route} ->
          put(id, route, ttl: ttl())

          route

        _ ->
          nil
      end
    end
  end

  def ttl do
    additional_minutes = :rand.uniform(30)
    @base_ttl + :timer.minutes(additional_minutes)
  end
end
