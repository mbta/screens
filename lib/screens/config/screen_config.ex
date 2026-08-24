defmodule Screens.Config.ScreenConfig do
  use Ecto.Schema

  alias Screens.Config.ScreenConfigType
  alias ScreensConfig.Screen

  import Ecto.Changeset

  @derive {Jason.Encoder, except: [:__meta__]}

  @type t() :: %__MODULE__{
          id: String.t(),
          config: Screen.t()
        }

  @primary_key {:id, :string, autogenerate: false}
  schema "screen_configs" do
    field :config, ScreenConfigType

    timestamps(type: :utc_datetime)
  end

  def changeset(screen_config, attrs) do
    screen_config
    |> cast(attrs, [:id, :config])
    |> validate_required([:id, :config])
  end

  @spec from_attrs(map()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def from_attrs(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> apply_action(:insert)
  end
end
