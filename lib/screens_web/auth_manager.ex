defmodule ScreensWeb.AuthManager do
  @moduledoc false

  use Guardian, otp_app: :screens

  @idle_time Application.compile_env!(:screens, [__MODULE__, :idle_time])
  @max_session_time Application.compile_env!(:screens, [__MODULE__, :max_session_time])

  @impl true
  def subject_for_token(resource, _claims) do
    {:ok, resource}
  end

  @impl true
  def resource_from_claims(%{"sub" => username}) do
    {:ok, username}
  end

  def resource_from_claims(_), do: {:error, :invalid_claims}

  @impl true
  def verify_claims(%{"auth_time" => user_authed_at, "iat" => token_issued_at} = claims, _opts) do
    auth_expires_at = user_authed_at + @max_session_time
    token_expires_at = token_issued_at + @idle_time

    # is either expiration time in the past?
    if min(auth_expires_at, token_expires_at) < System.system_time(:second) do
      {:error, {:auth_expired, claims["sub"]}}
    else
      {:ok, claims}
    end
  end
end
