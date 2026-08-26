defmodule ScreensWeb.AdminApiController do
  use ScreensWeb, :controller

  alias Screens.Config.Fetch, as: ConfigFetch
  alias Screens.{Image, Util}
  alias Screens.ScreenConfigs
  alias ScreensConfig.{Config, Screen}

  plug :accepts, ["multipart/form-data"] when action == :upload_image

  def index(conn, _params) do
    config = ScreenConfigs.list_all()
    config_migration = ScreenConfigs.config_migration_enabled?()
    json(conn, %{config: config, config_migration: config_migration})
  end

  def update_screen_configs(conn, %{"screen_configs" => screen_configs})
      when is_list(screen_configs) do
    case ScreenConfigs.commit_updates(screen_configs) do
      :ok ->
        json(conn, %{success: true})

      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{success: false, error: inspect(reason)})
    end
  end

  def update_screen_configs(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{success: false, error: "Invalid request parameters"})
  end

  def delete_screen_configs(conn, %{"deleted_screen_ids" => deleted_screen_ids})
      when is_list(deleted_screen_ids) do
    case ScreenConfigs.commit_deletes(deleted_screen_ids) do
      :ok ->
        json(conn, %{success: true})

      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{success: false, error: inspect(reason)})
    end
  end

  def delete_screen_configs(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{success: false, error: "Invalid request parameters"})
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
    screen = screen_json |> Jason.decode!() |> Screen.from_json()
    %Config{screens: screens} = config = fetch_config()

    %Config{config | screens: Map.put(screens, id, screen)}
    |> put_config()
    |> to_success_response(conn)
  end

  def confirm(conn, %{"config" => config}) do
    config |> Jason.decode!() |> Config.from_json() |> put_config() |> to_success_response(conn)
  end

  def refresh(conn, %{"screen_ids" => screen_ids}) do
    fetch_config()
    |> Config.schedule_refresh_for_screen_ids(screen_ids)
    |> put_config()
    |> to_success_response(conn)
  end

  def list_images(conn, _params) do
    json(conn, %{images: Image.list()})
  end

  @spec import_configs(Plug.Conn.t(), map()) :: Plug.Conn.t()
  # This should be a part of post_config_migration_cleanup
  def import_configs(conn, _params) do
    case ScreenConfigs.import_from_file() do
      {:ok, %{upserted: upserted, deleted: deleted}} ->
        json(conn, %{upserted: upserted, deleted: deleted})

      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{success: false, error: inspect(reason)})
    end
  end

  def upload_image(conn, %{"image" => %Plug.Upload{} = upload, "key" => key}) do
    key |> Image.upload(upload) |> to_success_response(conn)
  end

  def delete_image(conn, %{"key" => key}) do
    key |> Image.delete() |> to_success_response(conn)
  end

  def maintenance(conn, %{"action" => "content_cleanup", "before" => iso_date, "dry_run" => _}) do
    before_date = Date.from_iso8601!(iso_date)

    affected =
      if ScreenConfigs.config_migration_enabled?() do
        ScreenConfigs.all()
        |> Util.Admin.expired_evergreen_content_count(before_date)
      else
        %Config{screens: screens} = fetch_config()

        Enum.count(screens, fn {_id, screen} ->
          screen != Util.Admin.cleanup_evergreen_content(screen, before_date)
        end)
      end

    json(conn, %{affected: affected})
  end

  def maintenance(conn, %{"action" => "content_cleanup", "before" => iso_date}) do
    before_date = Date.from_iso8601!(iso_date)

    if ScreenConfigs.config_migration_enabled?() do
      response =
        ScreenConfigs.all()
        |> Util.Admin.evergreen_content_cleanup_updates(before_date)
        |> ScreenConfigs.commit_updates()

      case response do
        :ok ->
          json(conn, %{success: true})

        {:error, reason} ->
          conn
          |> put_status(500)
          |> json(%{success: false, error: inspect(reason)})
      end
    else
      %Config{screens: screens} = config = fetch_config()

      new_screens =
        screens
        |> Enum.map(fn {id, screen} ->
          {id, Util.Admin.cleanup_evergreen_content(screen, before_date)}
        end)
        |> Map.new()

      %Config{config | screens: new_screens}
      |> put_config()
      |> to_success_response(conn)
    end
  end

  @spec fetch_config() :: Config.t()
  defp fetch_config do
    {:ok, config_json, _version} = ConfigFetch.fetch_config()
    config_json |> Jason.decode!() |> Config.from_json()
  end

  @spec put_config(Config.t()) :: :ok | :error
  defp put_config(%Config{} = config) do
    config
    |> Config.to_json()
    |> Jason.encode!(pretty: true)
    |> ConfigFetch.put_config()
  end

  @spec to_success_response(:ok | :error, Plug.Conn.t()) :: Plug.Conn.t()
  defp to_success_response(result, conn) do
    success =
      case result do
        :ok -> true
        :error -> false
      end

    json(conn, %{success: success})
  end
end
