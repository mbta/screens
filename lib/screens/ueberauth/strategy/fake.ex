defmodule Screens.Ueberauth.Strategy.Fake do
  @moduledoc false

  use Ueberauth.Strategy, ignores_csrf_attack: true

  @impl Ueberauth.Strategy
  def handle_request!(conn) do
    conn
    |> redirect!("/auth/cognito/callback")
    |> halt()
  end

  @impl Ueberauth.Strategy
  def handle_callback!(conn) do
    conn
  end

  @impl Ueberauth.Strategy
  def uid(_conn) do
    "fake_uid"
  end

  @impl Ueberauth.Strategy
  def credentials(_conn) do
    %Ueberauth.Auth.Credentials{
      token: "fake_access_token",
      refresh_token: "fake_refresh_token",
      expires: true,
      expires_at: System.system_time(:second) + 60 * 60,
      other: %{groups: [Application.get_env(:screens, :cognito_group)]}
    }
  end

  @impl Ueberauth.Strategy
  def info(_conn) do
    %Ueberauth.Auth.Info{}
  end

  @impl Ueberauth.Strategy
  def extra(_conn) do
    %Ueberauth.Auth.Extra{raw_info: %{}}
  end

  @impl Ueberauth.Strategy
  def handle_cleanup!(conn) do
    conn
  end
end
