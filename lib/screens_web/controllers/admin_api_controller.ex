defmodule ScreensWeb.AdminApiController do
  use ScreensWeb, :controller

  alias Screens.Config.Backup
  alias Screens.Config.Backup.Rollback
  alias Screens.{Image, Util}
  alias Screens.ScreenConfigs
  alias ScreensConfig.{Config, Screen}

  plug :accepts, ["multipart/form-data"] when action == :upload_image

  def index(conn, _params) do
    config = ScreenConfigs.list_all()
    json(conn, %{config: config})
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

  def refresh(conn, %{"screen_ids" => screen_ids}) do
    screen_ids
    |> ScreenConfigs.schedule_refresh_for_screen_ids()
    |> to_success_response(conn)
  end

  def list_images(conn, _params) do
    json(conn, %{images: Image.list()})
  end

  @doc "Environments whose config backups can be restored into this environment."
  @spec sync_environments(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def sync_environments(conn, _params) do
    json(conn, %{environments: Backup.environments()})
  end

  @doc "Dates for which the current environment has a daily config backup."
  @spec backup_dates(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def backup_dates(conn, _params) do
    case Rollback.dates() do
      {:ok, dates} ->
        json(conn, %{dates: dates})

      :error ->
        conn
        |> put_status(500)
        |> json(%{success: false, error: "Could not list daily backups"})
    end
  end

  @doc "Returns current and backed up screen configs for a side-by-side comparison."
  @spec daily_backup_comparison(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def daily_backup_comparison(conn, %{"date" => date}) do
    case Rollback.compare_daily(date) do
      {:ok, comparison} ->
        json(conn, comparison)

      {:error, :invalid_date} ->
        conn
        |> put_status(400)
        |> json(%{success: false, error: "Invalid backup date"})

      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{success: false, error: inspect(reason)})
    end
  end

  def daily_backup_comparison(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{success: false, error: "Invalid request parameters"})
  end

  @doc "Replaces all screen configs with the current environment's daily backup from a date."
  @spec restore_daily_backup(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def restore_daily_backup(conn, %{"date" => date}) do
    case Rollback.restore_daily(date) do
      {:ok, %{upserted: upserted, deleted: deleted}} ->
        json(conn, %{success: true, upserted: upserted, deleted: deleted})

      {:error, :invalid_date} ->
        conn
        |> put_status(400)
        |> json(%{success: false, error: "Invalid backup date"})

      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{success: false, error: inspect(reason)})
    end
  end

  def restore_daily_backup(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{success: false, error: "Invalid request parameters"})
  end

  @doc "Replaces all screen configs with the contents of the given environment's snapshot."
  @spec sync_from_snapshot(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def sync_from_snapshot(conn, %{"environment" => environment}) do
    case Backup.restore(environment) do
      {:ok, %{upserted: upserted, deleted: deleted, assets_copied: assets_copied}} ->
        json(conn, %{
          success: true,
          upserted: upserted,
          deleted: deleted,
          assets_copied: assets_copied
        })

      {:error, :environment_not_allowed} ->
        conn
        |> put_status(400)
        |> json(%{success: false, error: "Cannot restore from #{inspect(environment)}"})

      {:error, reason} ->
        conn
        |> put_status(500)
        |> json(%{success: false, error: inspect(reason)})
    end
  end

  def sync_from_snapshot(conn, _params) do
    conn
    |> put_status(400)
    |> json(%{success: false, error: "Invalid request parameters"})
  end

  def upload_image(conn, %{"image" => %Plug.Upload{} = upload, "key" => key}) do
    key |> Image.upload(upload) |> to_success_response(conn)
  end

  def delete_image(conn, %{"key" => key}) do
    key |> Image.delete() |> to_success_response(conn)
  end

  def maintenance(conn, %{"action" => "content_cleanup", "before" => iso_date, "dry_run" => _}) do
    before_date = Date.from_iso8601!(iso_date)

    affected = Util.Admin.expired_evergreen_content_count(ScreenConfigs.all(), before_date)

    json(conn, %{affected: affected})
  end

  def maintenance(conn, %{"action" => "content_cleanup", "before" => iso_date}) do
    before_date = Date.from_iso8601!(iso_date)

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
  end

  @spec to_success_response(:ok | :error, Plug.Conn.t()) :: Plug.Conn.t()
  defp to_success_response(result, conn) do
    response =
      case result do
        :ok -> %{success: true}
        :error -> %{success: false}
        {:error, reason} -> %{success: false, error: inspect(reason)}
      end

    json(conn, response)
  end
end
