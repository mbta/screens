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

  def refresh(conn, %{"screen_ids" => screen_ids}) do
    current_config = Config.State.config()
    new_config = Config.schedule_refresh_for_screen_ids(current_config, screen_ids)
    {:ok, new_config_json} = Jason.encode(Config.to_json(new_config), pretty: true)

    success =
      case @config_fetcher.put_to_s3(new_config_json) do
        :ok -> true
        :error -> false
      end

    json(conn, %{success: success})
  end
end
