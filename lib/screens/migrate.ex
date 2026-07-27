defmodule Screens.Migrate do
  @moduledoc """
  GenServer which runs on startup to run Ecto migrations. All migrations
  stored in the "migrations" directory are run during init. Migrations stored
  in the "async_migrations" directory will be run after the regular migrations
  complete and will only log a warning on failure.
  """
  use GenServer, restart: :transient
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(opts) do
    Logger.info("#{__MODULE__} synchronous migrations starting")
    Keyword.get(opts, :sync_migrate_fn, &default_migrate_fn/1).("migrations")

    Logger.info("#{__MODULE__} synchronous migrations finished")
    {:ok, opts}
  end

  defp default_migrate_fn(migration_directory) do
    Ecto.Migrator.run(
      Screens.Repo,
      Ecto.Migrator.migrations_path(Screens.Repo, migration_directory),
      :up,
      all: true
    )
  end
end
