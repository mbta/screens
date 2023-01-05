defmodule Screens.V2.WidgetInstance.DeparturesNoService do
  @moduledoc false

  defstruct screen: nil

  @type t :: %__MODULE__{
          screen: Screens.Config.Screen.t()
        }

  def priority(_instance), do: [2]
  def serialize(_instance), do: %{}
  def slot_names(_instance), do: [:main_content]
  def widget_type(_instance), do: :departures_no_service
  def valid_candidate?(_instance), do: true

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.DeparturesNoService

    def priority(instance), do: DeparturesNoService.priority(instance)
    def serialize(instance), do: DeparturesNoService.serialize(instance)
    def slot_names(instance), do: DeparturesNoService.slot_names(instance)
    def widget_type(instance), do: DeparturesNoService.widget_type(instance)
    def valid_candidate?(instance), do: DeparturesNoService.valid_candidate?(instance)
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.DeparturesNoServiceView
  end
end
