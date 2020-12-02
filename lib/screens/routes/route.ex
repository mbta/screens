defmodule Screens.Routes.Route do
  @moduledoc false

  defstruct id: nil,
            short_name: nil,
            direction_destinations: nil,
            line_id: nil

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id,
          short_name: String.t(),
          direction_destinations: list(),
          stop_id: id | nil,
          line_id: id | nil
        }

  def by_id(route_id) do
    case Screens.V3Api.get_json("routes/" <> route_id) do
      {:ok, %{"data" => data}} -> {:ok, Screens.Routes.Parser.parse_route(data)}
      _ -> :error
    end
  end

  def fetch(opts \\ []) do
    params =
      opts
      |> Enum.flat_map(&format_query_param/1)
      |> Enum.into(%{})

    case Screens.V3Api.get_json("routes", params) do
      {:ok, %{"data" => data}} -> {:ok, Enum.map(data, &Screens.Routes.Parser.parse_route/1)}
      _ -> :error
    end
  end

  defp format_query_param({:stop_ids, stop_ids}) do
    [
      {"filter[stop]", Enum.join(stop_ids, ",")}
    ]
  end

  defp format_query_param({:route_types, route_types}) do
    route_types =
      route_types
      |> Enum.map(&Screens.RouteType.to_id/1)
      |> Enum.join(",")

    [
      {"filter[type]", route_types}
    ]
  end

  defp format_query_param({:include, included_resources}) do
    [
      {"include", Enum.join(included_resources, ",")}
    ]
  end

  defp format_query_param(_), do: []
end
