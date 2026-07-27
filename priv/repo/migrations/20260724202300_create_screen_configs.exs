defmodule Screens.Repo.Migrations.CreateScreenConfigs do
  use Ecto.Migration

  def change do
    create table(:screen_configs, primary_key: false) do
      add :id, :string, primary_key: true
      add :config, :jsonb

      timestamps(type: :utc_datetime)
    end
  end
end
