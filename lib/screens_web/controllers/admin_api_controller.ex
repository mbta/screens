defmodule ScreensWeb.AdminApiController do
  use ScreensWeb, :controller

  alias Screens.Config.Cache, as: ConfigCache
  alias Screens.Config.Fetch, as: ConfigFetch
  alias Screens.Image
  alias ScreensConfig.{Config, Devops, Screen}

  plug :accepts, ["multipart/form-data"] when action == :upload_image

  def index(conn, _params) do
    {:ok, config, _version} = ConfigFetch.fetch_config()
    json(conn, %{config: config})
  end

  def validate(conn, %{"id" => _id, "config" => screen_json}) do
    validated_json = screen_json |> Jason.decode!() |> Screen.from_json() |> Screen.to_json()
    json(conn, %{success: true, config: validated_json})
  end

  def validate(conn, %{"config" => config}) do
    validated_json = config |> Jason.decode!() |> Config.from_json() |> Config.to_json()
    json(conn, %{success: true, config: validated_json})
  end

  def confirm(conn, %{"id" => id, "config" => screen_json}) do
    {:ok, config_json, _version} = ConfigFetch.fetch_config()
    config = config_json |> Jason.decode!() |> Config.from_json()
    %Screen{app_id: app_id} = screen = screen_json |> Jason.decode!() |> Screen.from_json()

    new_config = %Config{
      config
      | screens: Map.update!(config.screens, id, fn %Screen{app_id: ^app_id} -> screen end)
    }

    new_config_json = new_config |> Config.to_json() |> Jason.encode!(pretty: true)

    success =
      case ConfigFetch.put_config(new_config_json) do
        :ok -> true
        :error -> false
      end

    json(conn, %{success: success})
  end

  def confirm(conn, %{"config" => config}) do
    current_devops_config = ConfigCache.devops()
    %Config{screens: new_screens_config} = config |> Jason.decode!() |> Config.from_json()
    new_config = %Config{screens: new_screens_config, devops: current_devops_config}
    new_config_json = new_config |> Config.to_json() |> Jason.encode!(pretty: true)

    success =
      case ConfigFetch.put_config(new_config_json) do
        :ok -> true
        :error -> false
      end

    json(conn, %{success: success})
  end

  def devops(conn, %{"disabled_modes" => _disabled_modes} = json) do
    current_screens_config = ConfigCache.screens()
    new_devops_config = Devops.from_json(json)
    new_config = %Config{screens: current_screens_config, devops: new_devops_config}
    new_config_json = new_config |> Config.to_json() |> Jason.encode!(pretty: true)

    success =
      case ConfigFetch.put_config(new_config_json) do
        :ok -> true
        :error -> false
      end

    json(conn, %{success: success})
  end

  def refresh(conn, %{"screen_ids" => screen_ids}) do
    %Config{} = current_config = ConfigCache.config()

    new_config = Config.schedule_refresh_for_screen_ids(current_config, screen_ids)
    {:ok, new_config_json} = Jason.encode(Config.to_json(new_config), pretty: true)

    success =
      case ConfigFetch.put_config(new_config_json) do
        :ok -> true
        :error -> false
      end

    json(conn, %{success: success})
  end

  def list_images(conn, _params) do
    json(conn, %{images: Image.list()})
  end

  def upload_image(conn, %{"image" => %Plug.Upload{} = upload, "key" => key}) do
    response =
      case Image.upload(key, upload) do
        :ok -> %{success: true}
        :error -> %{success: false}
      end

    json(conn, response)
  end

  def delete_image(conn, %{"key" => key}) do
    response =
      case Image.delete(key) do
        :ok -> %{success: true}
        :error -> %{success: false}
      end

    json(conn, response)
  end
end
