defmodule ScreensWeb.AdminApiController do
  use ScreensWeb, :controller

  alias Screens.Config

  @config_fetcher Application.get_env(:screens, :config_fetcher)

  def index(conn, _params) do
    {:ok, config} = @config_fetcher.get_from_s3()
    json(conn, %{config: config})
  end

  def validate(conn, %{"config" => config}) do
    validated_json = config |> Jason.decode!() |> Config.from_json() |> Config.to_json()
    json(conn, %{config: validated_json})
  end

  def confirm(conn, %{"config" => config}) do
    success =
      case @config_fetcher.put_to_s3(config) do
        :ok -> true
        :error -> false
      end

    json(conn, %{success: success})
  end
end
