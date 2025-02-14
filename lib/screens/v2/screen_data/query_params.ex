defmodule Screens.V2.ScreenData.QueryParams do
  @moduledoc """
  Processes valid query parameters.
  """
  @type t :: %__MODULE__{
          route_id: String.t() | nil,
          stop_id: String.t() | nil,
          trip_id: String.t() | nil
        }

  defstruct route_id: nil, stop_id: nil, trip_id: nil

  # To add new URL params, this list needs to be updated.
  # Currently, it only contains query param keys used by on bus screens.
  @valid_param_keys ["route_id", "stop_id", "trip_id"]

  @doc "Returns a QueryParam struct of all valid query param keys and corresponding values."
  @spec get_url_param_map(Plug.Conn.t()) :: struct()
  def get_url_param_map(conn) do
    conn
    |> Map.get(:query_params, %{})
    |> Map.take(@valid_param_keys)
    |> Enum.filter(fn {_key, value} -> value != "" end)
    |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)
    |> then(&struct(__MODULE__, &1))
  end
end
