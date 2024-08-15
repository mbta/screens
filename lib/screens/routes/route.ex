defmodule Screens.Routes.Route do
  @moduledoc false

  require Logger

  alias Screens.Routes.Parser
  alias Screens.RouteType
  alias Screens.Stops.Stop
  alias Screens.V3Api

  @sl_route_ids ~w[741 742 743 746 749 751]

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
          type: RouteType.t()
        }

  @type params :: %{
          optional(:ids) => [id()],
          optional(:stop_id) => Stop.id(),
          optional(:stop_ids) => [Stop.id()],
          optional(:date) => Date.t() | DateTime.t(),
          optional(:route_types) => [RouteType.t()] | RouteType.t(),
          optional(:limit) => pos_integer()
        }

  @typep name_colors :: :blue | :green | :orange | :red | :silver
  @type color :: name_colors() | :purple | :teal | :yellow
  @type icon :: name_colors() | :bus | :cr | :ferry | :mattapan

  @callback by_id(id()) :: {:ok, t()} | :error
  @spec by_id(id()) :: {:ok, t()} | :error
  def by_id(route_id) do
    case V3Api.get_json("routes/" <> route_id) do
      {:ok, %{"data" => data}} -> {:ok, Parser.parse_route(data)}
      _ -> :error
    end
  end

  @spec fetch() :: {:ok, [t()]} | :error
  @spec fetch(params()) :: {:ok, [t()]} | :error
  def fetch(opts \\ [], get_json_fn \\ &V3Api.get_json/2) do
    params =
      opts
      |> Enum.flat_map(&format_query_param/1)
      |> Enum.into(%{})

    case get_json_fn.("routes/", params) do
      {:ok, %{"data" => data}} -> {:ok, Enum.map(data, &Parser.parse_route/1)}
      _ -> :error
    end
  end

  @doc "Fetches routes that serve the given stop."
  @callback serving_stop(Stop.id()) :: {:ok, [t()]} | :error
  def serving_stop(
        stop_id,
        get_json_fn \\ &V3Api.get_json/2,
        attempts_left \\ 3
      )

  def serving_stop(_stop_id, _get_json_fn, 0), do: :error

  def serving_stop(
        stop_id,
        get_json_fn,
        attempts_left
      ) do
    case get_json_fn.("routes", %{"filter[stop]" => stop_id}) do
      {:ok, %{"data" => []}, _} ->
        Logger.warning("Route.serving_stop empty_retry attempts_left=#{attempts_left - 1}")
        serving_stop(stop_id, get_json_fn, attempts_left - 1)

      {:ok, %{"data" => data}} ->
        {:ok, Enum.map(data, fn route -> Parser.parse_route(route) end)}

      _ ->
        :error
    end
  end

  @doc """
  Similar to `serving_stop` but also determines whether each route has any scheduled service at
  the given stop on the current day. Only route IDs and the `active?` flag are returned.
  """
  @spec serving_stop_with_active(Stop.id()) ::
          {:ok, list(%{route_id: id(), active?: boolean()})} | :error
  def serving_stop_with_active(
        stop_id,
        now \\ DateTime.utc_now(),
        type_filters \\ [],
        get_json_fn \\ &V3Api.get_json/2,
        fetch_routes_fn \\ &fetch_routes/3
      ) do
    Screens.Telemetry.span(
      ~w[screens routes route serving_stop_with_active]a,
      %{stop_id: stop_id, type_filters: type_filters},
      fn ->
        with {:ok, routes} <- fetch_routes_fn.(stop_id, get_json_fn, type_filters),
             {:ok, active_route_ids} <- fetch_active_route_ids(stop_id, now, get_json_fn) do
          active_set = MapSet.new(active_route_ids)

          routes_at_stop =
            Enum.map(routes, &%{route_id: &1.id, active?: MapSet.member?(active_set, &1.id)})

          {:ok, routes_at_stop}
        else
          :error -> :error
        end
      end
    )
  end

  defp format_query_param({:ids, ids}) when is_list(ids) do
    [{"filter[id]", Enum.join(ids, ",")}]
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
    [{"filter[type]", Enum.map_join(route_types, ",", &RouteType.to_id/1)}]
  end

  defp format_query_param({:route_types, route_type}) do
    format_query_param({:route_types, [route_type]})
  end

  defp format_query_param({:limit, limit}) when is_integer(limit) and limit > 0 do
    [{"page[limit]", to_string(limit)}]
  end

  defp format_query_param(_), do: []

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

  @spec route_ids(list(%{route_id: id(), active?: boolean()})) :: list(id())
  def route_ids(routes), do: Enum.map(routes, & &1.route_id)

  @spec color(id()) :: color()
  @spec color(id(), RouteType.t() | nil) :: color()
  def color(route_id, route_type \\ nil)

  def color("Red", _), do: :red
  def color("Mattapan", _), do: :red
  def color("Orange", _), do: :orange
  def color("Green" <> _, _), do: :green
  def color("Blue", _), do: :blue
  def color("CR-" <> _, _), do: :purple
  def color("Boat-" <> _, _), do: :teal
  def color(route_id, _) when route_id in @sl_route_ids, do: :silver
  def color(_, :rail), do: :purple
  def color(_, :ferry), do: :teal
  def color(_, _), do: :yellow

  @doc """
  Returns an "icon", as understood by `FreeText` or `RoutePill.serialize_icon/1`, for a route.
  Somewhat specific to "no service" or "no data" states where a single pill represents a group of
  routes, hence all bus routes are `:bus`, all GL routes are `:green`, etc.
  """
  @spec icon(t()) :: icon()
  def icon(%{id: "Blue"}), do: :blue
  def icon(%{id: "Boat-" <> _}), do: :ferry
  def icon(%{id: "CR-" <> _}), do: :cr
  def icon(%{id: "Green" <> _}), do: :green
  def icon(%{id: "Mattapan"}), do: :mattapan
  def icon(%{id: "Orange"}), do: :orange
  def icon(%{id: "Red"}), do: :red
  def icon(%{id: id}) when id in @sl_route_ids, do: :silver
  def icon(%{short_name: "SL" <> _}), do: :silver
  def icon(%{type: :bus}), do: :bus
  def icon(%{type: :ferry}), do: :ferry
  def icon(%{type: :rail}), do: :cr
  def icon(_), do: :bus
end
