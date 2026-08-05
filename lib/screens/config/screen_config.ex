defmodule Screens.Config.ScreenConfig do
  use Ecto.Schema

  alias ScreensConfig.Config

  import Ecto.Changeset

  @type t() :: %__MODULE__{
          id: String.t(),
          config: Config.t()
        }

  @primary_key {:id, :string, autogenerate: false}
  schema "screen_configs" do
    field :config, :map

    timestamps(type: :utc_datetime)
  end

  def changeset(screen_config, attrs) do
    screen_config
    |> cast(attrs, [:id, :config])
    |> validate_required([:id, :config])
  end
end
