defmodule Screens.Stops.Stop do
  @moduledoc false

  require Logger

  alias Screens.LocationContext
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Stops
  alias Screens.Util
  alias Screens.V3Api
  alias ScreensConfig.V2.{BusEink, BusShelter, Dup, GlEink, PreFare}

  defstruct ~w[id name location_type platform_code platform_name]a

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id,
          name: String.t(),
          location_type: 0 | 1 | 2 | 3,
          platform_code: String.t() | nil,
          platform_name: String.t() | nil
        }

  @type screen_type :: BusEink | BusShelter | GlEink | PreFare | Dup

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

  @callback fetch_stop_name(id()) :: String.t() | nil
  def fetch_stop_name(stop_id) do
    Screens.Telemetry.span(~w[screens stops stop fetch_stop_name]a, %{stop_id: stop_id}, fn ->
      case Screens.V3Api.get_json("stops", %{"filter[id]" => stop_id}) do
        {:ok, %{"data" => [stop_data]}} ->
          %{"attributes" => %{"name" => stop_name}} = stop_data
          stop_name

        _ ->
          nil
      end
    end)
  end

  def fetch_subway_platforms_for_stop(stop_id) do
    case Screens.V3Api.get_json("stops/" <> stop_id, %{"include" => "child_stops"}) do
      {:ok, %{"included" => child_stop_data}} ->
        child_stop_data
        |> Enum.filter(fn %{
                            "attributes" => %{
                              "location_type" => location_type,
                              "vehicle_type" => vehicle_type
                            }
                          } ->
          location_type == 0 and vehicle_type in [0, 1]
        end)
        |> Enum.map(&Stops.Parser.parse_stop/1)
    end
  end

  @doc """
  Returns a list of child stops for each given stop ID (in the same order). For stop IDs that are
  already child stops, the list contains only the stop itself. For stop IDs that do not exist, the
  list is empty.
  """
  @callback fetch_child_stops([id()]) :: {:ok, [[t()]]} | {:error, term()}
  def fetch_child_stops(stop_ids, get_json_fn \\ &Screens.V3Api.get_json/2) do
    case get_json_fn.("stops", %{
           "filter[id]" => Enum.join(stop_ids, ","),
           "include" => "child_stops"
         }) do
      {:ok, %{"data" => data} = response} ->
        child_stops =
          response
          |> Map.get("included", [])
          |> Enum.map(&Stops.Parser.parse_stop/1)
          |> Map.new(&{&1.id, &1})

        stops_with_children =
          data
          |> Enum.map(fn %{"relationships" => %{"child_stops" => %{"data" => children}}} = stop ->
            {
              Stops.Parser.parse_stop(stop),
              children
              |> Enum.map(fn %{"id" => id} -> Map.fetch!(child_stops, id) end)
              |> Enum.filter(&(&1.location_type == 0))
            }
          end)
          |> Map.new(&{elem(&1, 0).id, &1})

        {:ok,
         Enum.map(stop_ids, fn stop_id ->
           case stops_with_children[stop_id] do
             nil -> []
             {stop, []} -> [stop]
             {_stop, children} -> children
           end
         end)}

      error ->
        {:error, error}
    end
  end

  @doc """
  Fetches all the location context for a screen given its app type, stop id, and time
  """
  @spec fetch_location_context(
          screen_type(),
          id(),
          DateTime.t()
        ) :: {:ok, LocationContext.t()} | :error
  def fetch_location_context(app, stop_id, now) do
    Screens.Telemetry.span(
      ~w[screens stops stop fetch_location_context]a,
      %{app: app, stop_id: stop_id},
      fn ->
        with alert_route_types <- get_route_type_filter(app, stop_id),
             {:ok, routes_at_stop} <-
               Route.serving_stop_with_active(stop_id, now, alert_route_types),
             {:ok, tagged_stop_sequences} <-
               fetch_tagged_stop_sequences_by_app(app, stop_id, routes_at_stop) do
          stop_name = fetch_stop_name(stop_id)
          stop_sequences = RoutePattern.untag_stop_sequences(tagged_stop_sequences)

          {:ok,
           %LocationContext{
             home_stop: stop_id,
             home_stop_name: stop_name,
             tagged_stop_sequences: tagged_stop_sequences,
             upstream_stops: upstream_stop_id_set(stop_id, stop_sequences),
             downstream_stops: downstream_stop_id_set(stop_id, stop_sequences),
             routes: routes_at_stop,
             alert_route_types: alert_route_types
           }}
        else
          :error ->
            Logger.error(
              "[fetch_location_context fetch error] Failed to get location context for an alert: stop_id=#{stop_id}"
            )

            :error
        end
      end
    )
  end

  # Returns the route types we care about for the alerts of this screen type / place
  @spec get_route_type_filter(screen_type(), String.t()) :: list(RouteType.t())
  def get_route_type_filter(app, _) when app in [BusEink, BusShelter], do: [:bus]
  def get_route_type_filter(GlEink, _), do: [:light_rail]
  # Ashmont should not show Mattapan alerts for PreFare or Dup
  def get_route_type_filter(app, "place-asmnl") when app in [PreFare, Dup], do: [:subway]
  def get_route_type_filter(PreFare, _), do: [:light_rail, :subway]
  # WTC is a special bus-only case
  def get_route_type_filter(Dup, "place-wtcst"), do: [:bus]
  def get_route_type_filter(Dup, _), do: [:light_rail, :subway]

  @spec upstream_stop_id_set(String.t(), list(list(id()))) :: MapSet.t(id())
  def upstream_stop_id_set(stop_id, stop_sequences) do
    stop_sequences
    |> Enum.flat_map(fn stop_sequence -> Util.slice_before(stop_sequence, stop_id) end)
    |> MapSet.new()
  end

  @spec downstream_stop_id_set(String.t(), list(list(id()))) :: MapSet.t(id())
  def downstream_stop_id_set(stop_id, stop_sequences) do
    stop_sequences
    |> Enum.flat_map(fn stop_sequence -> Util.slice_after(stop_sequence, stop_id) end)
    |> MapSet.new()
  end

  defp fetch_tagged_stop_sequences_by_app(app, stop_id, _routes_at_stop)
       when app in [BusEink, BusShelter, GlEink] do
    RoutePattern.fetch_tagged_stop_sequences_through_stop(stop_id)
  end

  defp fetch_tagged_stop_sequences_by_app(Dup, stop_id, routes_at_stop) do
    route_ids = Route.route_ids(routes_at_stop)
    RoutePattern.fetch_tagged_parent_station_sequences_through_stop(stop_id, route_ids)
  end

  defp fetch_tagged_stop_sequences_by_app(PreFare, stop_id, routes_at_stop) do
    route_ids = Route.route_ids(routes_at_stop)

    # We limit results to canonical route patterns only--no stop sequences for nonstandard patterns.
    RoutePattern.fetch_tagged_parent_station_sequences_through_stop(stop_id, route_ids, true)
  end
end
