defmodule Screens.V2.ScreenData.QueryParams do
  @moduledoc "Encodes valid query parameters that are currently only used by on bus screens."
  alias Screens.V2.ScreenData.QueryParams

  @type t :: %__MODULE__{
          route_id: String.t() | nil,
          stop_id: String.t() | nil,
          trip_id: String.t() | nil
        }

  defstruct route_id: nil, stop_id: nil, trip_id: nil

  # Valid keys for URL parameters to be passed into the screen app.
  # To process a new URL parameter, it needs to be added to this list.
  @valid_param_keys ["route_id", "stop_id", "trip_id"]
  def valid_param_keys() do
    @valid_param_keys
  end

  @spec get_url_param_map(Plug.Conn.t()) :: struct()
  def get_url_param_map(conn) do
    conn
    |> Plug.Conn.fetch_query_params()
    |> Map.get(:query_params, %{})
    |> Map.take(@valid_param_keys)
    |> Enum.filter(fn {_key, value} -> value != "" end)
    |> Enum.into(%{}, fn {key, value} -> {String.to_atom(key), value} end)
    |> then(&struct(__MODULE__, &1))
  end

  @spec get_url_param_list(Plug.Conn.t()) :: list()
  def get_url_param_list(conn) do
    IO.inspect(QueryParams.get_url_param_map(conn))

    QueryParams.valid_param_keys()
    |> Enum.map(fn key ->
      value = Map.get(QueryParams.get_url_param_map(conn), String.to_atom(key))
      {String.to_atom(key), value}
    end)
    |> Enum.filter(fn {_key, value} -> value != nil end)
  end
end
