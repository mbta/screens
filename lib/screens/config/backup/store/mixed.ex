defmodule Screens.Config.Backup.Store.Mixed do
  @moduledoc """
  A store for local development: always writes backups to the local file, but fetches backups
  from the local file for the "local" environment and from S3 for any other (real) environment.
  This allows pulling down a real environment's configs while never writing backups to S3.
  """

  @behaviour Screens.Config.Backup.Store

  alias Screens.Config.Backup.Store.Local
  alias Screens.Config.Backup.Store.S3

  @impl true
  def fetch_backup("local"), do: Local.fetch_backup("local")
  def fetch_backup(environment), do: S3.fetch_backup(environment)

  @impl true
  def put_backup(file_contents), do: Local.put_backup(file_contents)
end
