defmodule Screens.Stops.Stop do
  @moduledoc false

  require Logger

  alias Screens.Stops
  alias Screens.V3Api

  defstruct ~w[id name location_type platform_code platform_name]a

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id,
          name: String.t(),
          location_type: 0 | 1 | 2 | 3,
          platform_code: String.t() | nil,
          platform_name: String.t() | nil
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
end
