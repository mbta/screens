defmodule ScreensWeb.AdminApiController do
  use ScreensWeb, :controller

  alias Screens.Config.Cache, as: ConfigCache
  alias Screens.Config.Fetch, as: ConfigFetch
  alias Screens.Image
  alias Screens.TriptychPlayer
  alias Screens.TriptychPlayer.Fetch, as: TriptychPlayerFetch
  alias ScreensConfig.{Config, Devops}

  plug :accepts, ["multipart/form-data"] when action == :upload_image

  def index(conn, _params) do
    {:ok, config, _version} = ConfigFetch.fetch_config()
    json(conn, %{config: config})
  end

  def validate(conn, %{"config" => config}) do
    validated_json = config |> Jason.decode!() |> Config.from_json() |> Config.to_json()
    json(conn, %{success: true, config: validated_json})
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

  def index_triptych_players(conn, _params) do
    {:ok, mapping, _version} = TriptychPlayerFetch.fetch_config()
    json(conn, %{config: mapping})
  end

  def validate_triptych_players(conn, %{"config" => config}) do
    with {:ok, mapping} <- Jason.decode(config),
         :ok <- TriptychPlayer.validate(mapping) do
      json(conn, %{success: true, config: mapping})
    else
      {:error, message} when is_binary(message) ->
        json(conn, %{success: false, message: message})

      {:error, jason_exception} when is_exception(jason_exception) ->
        json(conn, %{success: false, message: Exception.message(jason_exception)})
    end
  end

  def confirm_triptych_players(conn, %{"config" => config}) do
    pretty_json = config |> Jason.decode!() |> Jason.encode!(pretty: true)

    success =
      case TriptychPlayerFetch.put_config(pretty_json) do
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

  def image_filenames(conn, _params) do
    image_filenames = Image.fetch_image_filenames()
    json(conn, %{image_filenames: image_filenames})
  end

  def upload_image(conn, %{"image" => %Plug.Upload{} = upload_struct}) do
    response =
      case Image.upload_image(upload_struct) do
        {:ok, uploaded_name} -> %{success: true, uploaded_name: uploaded_name}
        :error -> %{success: false}
      end

    json(conn, response)
  end

  def delete_image(conn, %{"filename" => filename}) do
    response =
      case Image.delete_image(filename) do
        :ok -> %{success: true}
        :error -> %{success: false}
      end

    json(conn, response)
  end
end
