defmodule ScreensWeb.Plug.EnsureBearerToken do
  @moduledoc """
  Ensures requests include a valid bearer token in the Authorization header.

  The expected token is loaded from an environment variable.
  """

  import Plug.Conn

  def init(opts) do
    Keyword.fetch!(opts, :env_var)
  end

  def call(conn, env_var) do
    configured_token = System.get_env(env_var)
    bearer_token = bearer_token_from_header(conn)

    if valid_token?(configured_token, bearer_token) do
      conn
    else
      unauthorized(conn)
    end
  end

  defp bearer_token_from_header(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end

  defp valid_token?(configured_token, bearer_token)
       when is_binary(configured_token) and is_binary(bearer_token) do
    byte_size(configured_token) == byte_size(bearer_token) and
      Plug.Crypto.secure_compare(configured_token, bearer_token)
  end

  defp valid_token?(_configured_token, _bearer_token), do: false

  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, "{\"error\":\"unauthorized\"}")
    |> halt()
  end
end
