defmodule Screens.V2.WidgetInstance.Survey do
  @moduledoc false

  alias Screens.Config.Screen

  @enforce_keys ~w[screen enabled? medium_asset_url large_asset_url]a
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          screen: Screen.t(),
          enabled?: boolean(),
          medium_asset_url: String.t(),
          large_asset_url: String.t()
        }

  @flex_zone_priority 2

  @survey_priority 10

  def priority(%__MODULE__{}), do: [@flex_zone_priority, @survey_priority]

  def serialize(%__MODULE__{medium_asset_url: medium_asset_url, large_asset_url: large_asset_url}) do
    %{
      medium_asset_url: medium_asset_url,
      large_asset_url: large_asset_url
    }
  end

  def slot_names(%__MODULE__{screen: %Screen{app_id: :bus_shelter_v2}}) do
    [:large, :medium_left, :medium_right]
  end

  def widget_type(%__MODULE__{}), do: :survey

  def valid_candidate?(%__MODULE__{enabled?: enabled?}), do: enabled?

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.Survey

    def priority(instance), do: Survey.priority(instance)
    def serialize(instance), do: Survey.serialize(instance)
    def slot_names(instance), do: Survey.slot_names(instance)
    def widget_type(instance), do: Survey.widget_type(instance)
    def valid_candidate?(instance), do: Survey.valid_candidate?(instance)
  end
end
