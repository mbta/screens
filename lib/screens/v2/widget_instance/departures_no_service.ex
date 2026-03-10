defmodule Screens.V2.WidgetInstance.DeparturesNoService do
  @moduledoc false
  alias Screens.V2.WidgetInstance.Serializer.RoutePill

  defstruct screen: nil, slot_name: nil, routes: []

  @type t :: %__MODULE__{
          screen: ScreensConfig.Screen.t(),
          slot_name: atom(),
          routes: list(atom())
        }

  def priority(_instance), do: [2]

  def serialize(instance), do: %{routes: Enum.map(instance.routes, &RoutePill.serialize_icon/1)}

  def slot_names(%__MODULE__{slot_name: slot_name}) when not is_nil(slot_name),
    do: [slot_name]

  def slot_names(_instance), do: [:main_content]
  def widget_type(_instance), do: :departures_no_service
  def valid_candidate?(_instance), do: true

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.DeparturesNoService

    def priority(instance), do: DeparturesNoService.priority(instance)
    def serialize(instance), do: DeparturesNoService.serialize(instance)
    def slot_names(instance), do: DeparturesNoService.slot_names(instance)
    def page_groups(_instance), do: []
    def widget_type(instance), do: DeparturesNoService.widget_type(instance)
    def valid_candidate?(instance), do: DeparturesNoService.valid_candidate?(instance)
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.NullView
  end
end
