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

  def refresh(conn, %{"screen_ids" => screen_id_json}) do
    {:ok, screen_ids} = Jason.decode(screen_id_json)

    %Config{screens: current_screens} = Config.State.config()

    new_screens =
      current_screens
      |> Enum.map(fn {screen_id, screen_config} ->
        new_screen_config =
          if screen_id in screen_ids do
            %Config.Screen{screen_config | refresh_if_loaded_before: DateTime.utc_now()}
          else
            screen_config
          end

        {screen_id, new_screen_config}
      end)
      |> Enum.into(%{})

    new_config = %Config{screens: new_screens}
    {:ok, new_config_json} = Jason.encode(Config.to_json(new_config), pretty: true)

    success =
      case @config_fetcher.put_to_s3(new_config_json) do
        :ok -> true
        :error -> false
      end

    json(conn, %{success: success})
  end
end
