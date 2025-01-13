defmodule ScreensWeb.AuthManager.Pipeline do
  @moduledoc false

  use Guardian.Plug.Pipeline,
    otp_app: :screens,
    error_handler: ScreensWeb.AuthManager.ErrorHandler,
    module: ScreensWeb.AuthManager

  plug :fetch_session
  plug :save_previous_path
  plug(Guardian.Plug.VerifySession, claims: %{"typ" => "access"})
  plug(Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"})
  plug(Guardian.Plug.LoadResource, allow_blank: true)
  plug :refresh_idle_token

  @doc """
  Refresh the token with each request.
  This allows us to use the `iat` time in the token as an idle timeout.
  """
  def refresh_idle_token(conn, _opts) do
    old_token = Guardian.Plug.current_token(conn)

    case ScreensWeb.AuthManager.refresh(old_token) do
      {:ok, _old, {new_token, _new_claims}} ->
        Guardian.Plug.put_session_token(conn, new_token)

      _ ->
        conn
    end
  end

  def save_previous_path(
        %Plug.Conn{query_string: query_string, request_path: request_path} = conn,
        _opts
      ) do
    Plug.Conn.put_session(conn, :previous_path, path_with_qs(request_path, query_string))
  end

  defp path_with_qs(path, ""), do: path
  defp path_with_qs(path, query), do: "#{path}?#{query}"
end
