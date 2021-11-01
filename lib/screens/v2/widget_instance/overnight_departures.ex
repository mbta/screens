defmodule Screens.V2.WidgetInstance.OvernightDepartures do
  @moduledoc false

  defstruct screen: nil

  @type t :: %__MODULE__{
          screen: Screens.Config.Screen.t()
        }

  def priority(_instance), do: [1]

  def serialize(_instance) do
    %{}
  end

  def slot_names(_instance), do: [:full_screen]
  def widget_type(_instance), do: :overnight_departures
  def valid_candidate?(_instance), do: true

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.OvernightDepartures

    def priority(instance), do: OvernightDepartures.priority(instance)
    def serialize(instance), do: OvernightDepartures.serialize(instance)
    def slot_names(instance), do: OvernightDepartures.slot_names(instance)
    def widget_type(instance), do: OvernightDepartures.widget_type(instance)
    def valid_candidate?(instance), do: OvernightDepartures.valid_candidate?(instance)
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: 0
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.OvernightDeparturesView
  end
end
