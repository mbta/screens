defmodule Screens.V2.WidgetInstance.Survey do
  @moduledoc false

  alias ScreensConfig.Screen

  @enforce_keys ~w[screen enabled? medium_asset_url large_asset_url]a
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          screen: Screen.t(),
          enabled?: boolean(),
          medium_asset_url: String.t(),
          large_asset_url: String.t()
        }

  def serialize(%__MODULE__{medium_asset_url: medium_asset_url, large_asset_url: large_asset_url}) do
    %{
      medium_asset_url: medium_asset_url,
      large_asset_url: large_asset_url
    }
  end

  def valid_candidate?(%__MODULE__{enabled?: enabled?}), do: enabled?

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.Survey

    def priority(_instance), do: [2, 10]
    def serialize(instance), do: Survey.serialize(instance)
    def slot_names(_instance), do: [:large, :medium_left, :medium_right]
    def widget_type(_instance), do: :survey
    def valid_candidate?(instance), do: Survey.valid_candidate?(instance)

    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.NullView
  end
end
