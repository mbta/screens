defmodule Screens.V2.ScreenData.QueryParams do
  @moduledoc """
  Encodes valid query parameters that are currently only used by on bus screens.
  Contains methods for processing query paramaters used by screen and api controllers.
  """
  @type t :: %__MODULE__{
          route_id: String.t() | nil,
          stop_id: String.t() | nil,
          trip_id: String.t() | nil
        }

  defstruct route_id: nil, stop_id: nil, trip_id: nil

  # Valid keys for URL parameters to be passed into the screen app.
  # To process a new URL parameter, it needs to be added to this list.
  @valid_param_keys ["route_id", "stop_id", "trip_id"]

  @doc "Returns a QueryParam struct of all valid query param keys and corresponding values."
  @spec get_url_param_map(Plug.Conn.t()) :: struct()
  def get_url_param_map(conn) do
    conn
    # |> Plug.Conn.fetch_query_params()
    |> Map.get(:query_params, %{})
    |> Map.take(@valid_param_keys)
    |> Enum.filter(fn {_key, value} -> value != "" end)
    |> Enum.into(%{}, fn {key, value} -> {String.to_existing_atom(key), value} end)
    |> then(&struct(__MODULE__, &1))
  end
end
