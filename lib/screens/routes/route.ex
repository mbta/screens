defmodule Screens.Routes.Route do
  @moduledoc false

  defstruct id: nil,
            short_name: nil,
            direction_destinations: nil,
            type: nil

  @type id :: String.t()

  @type route_type :: 0 | 1 | 2 | 3 | 4

  @type t :: %__MODULE__{
          id: id,
          short_name: String.t(),
          direction_destinations: list(String.t()),
          type: route_type
        }

  def by_id(route_id) do
    case Screens.V3Api.get_json("routes/" <> route_id) do
      {:ok, %{"data" => data}} -> {:ok, Screens.Routes.Parser.parse_route(data)}
      _ -> :error
    end
  end
end
