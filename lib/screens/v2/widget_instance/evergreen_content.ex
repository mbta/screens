defmodule Screens.V2.WidgetInstance.EvergreenContent do
  @moduledoc false

  @enforce_keys ~w[slot_names asset_url priority]a
  defstruct @enforce_keys

  def priority(%__MODULE__{} = instance), do: instance.priority

  def serialize(%__MODULE__{asset_url: asset_url}), do: %{asset_url: asset_url}

  def slot_names(%__MODULE__{slot_names: slot_names}), do: slot_names

  def widget_type(_instance), do: :evergreen_content

  def valid_candidate?(_instance), do: true

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.EvergreenContent

    def priority(instance), do: EvergreenContent.priority(instance)
    def serialize(instance), do: EvergreenContent.serialize(instance)
    def slot_names(instance), do: EvergreenContent.slot_names(instance)
    def widget_type(instance), do: EvergreenContent.widget_type(instance)
    def valid_candidate?(instance), do: EvergreenContent.valid_candidate?(instance)
  end
end
