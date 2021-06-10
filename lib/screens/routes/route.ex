defmodule Screens.Routes.Route do
  @moduledoc false

  defstruct id: nil,
            short_name: nil,
            direction_destinations: nil,
            type: nil

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id,
          short_name: String.t(),
          direction_destinations: list(String.t()),
          type: Screens.RouteType.t()
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

    case Screens.V3Api.get_json("routes/", params) do
      {:ok, %{"data" => data}} -> {:ok, Enum.map(data, &Screens.Routes.Parser.parse_route/1)}
      _ -> :error
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

  defp format_query_param(_), do: []
end
