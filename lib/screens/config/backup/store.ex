defmodule Screens.Config.Backup.Store do
  @moduledoc """
  Defines a behaviour for, and delegates to, a module that provides access to backups of the
  screen configs. Backups can be fetched for any environment, but are only ever written for the
  environment the app is running in.
  """

  @callback fetch_latest(environment :: String.t()) :: {:ok, String.t()} | :error
  @callback fetch_daily(environment :: String.t(), date :: Date.t()) ::
              {:ok, String.t()} | :error
  @callback list_daily(environment :: String.t()) :: {:ok, [String.t()]} | :error
  @callback put_latest(file_contents :: String.t()) :: :ok | :error
  @callback put_daily(file_contents :: String.t(), date :: Date.t()) :: :ok | :error

  @store Application.compile_env!(:screens, [Screens.Config.Backup, :store])

  defdelegate fetch_latest(environment), to: @store
  defdelegate fetch_daily(environment, date), to: @store
  defdelegate list_daily(environment), to: @store
  defdelegate put_latest(file_contents), to: @store
  defdelegate put_daily(file_contents, date), to: @store
end
