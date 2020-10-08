defmodule ScreensWeb.AdminApiController do
  use ScreensWeb, :controller

  alias Screens.{Config, Image}

  @config_fetcher Application.get_env(:screens, :config_fetcher)

  plug :accepts, ["multipart/form-data"] when action == :upload_image

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
