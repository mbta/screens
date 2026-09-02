defmodule Screens.Config.Backup.Store do
  @moduledoc """
  Defines a behaviour for, and delegates to, a module that provides access to backups of the
  screen configs. Backups can be fetched for any environment, but are only ever written for the
  environment the app is running in.
  """

  @callback fetch_backup(environment :: String.t()) :: {:ok, String.t()} | :error
  @callback put_backup(file_contents :: String.t()) :: :ok | :error

  @store Application.compile_env!(:screens, [Screens.Config.Backup, :store])

  defdelegate fetch_backup(environment), to: @store
  defdelegate put_backup(file_contents), to: @store
end
