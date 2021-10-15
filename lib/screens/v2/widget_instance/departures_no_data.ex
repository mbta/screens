defmodule Screens.V2.WidgetInstance.DeparturesNoData do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.BusShelter
  alias Screens.Config.V2.Header.CurrentStopId

  defstruct screen: nil, show_alternatives?: nil

  @type t :: %__MODULE__{
          screen: Screens.Config.Screen.t(),
          show_alternatives?: boolean()
        }

  def priority(_instance), do: [2]

  def serialize(%__MODULE__{} = instance) do
    %{show_alternatives: instance.show_alternatives?, stop_id: stop_id(instance)}
  end

  def slot_names(_instance), do: [:main_content]
  def widget_type(_instance), do: :departures_no_data
  def valid_candidate?(_instance), do: true

  defp stop_id(%__MODULE__{
         screen: %Screen{app_params: %BusShelter{header: %CurrentStopId{stop_id: stop_id}}}
       }) do
    stop_id
  end

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.DeparturesNoData

    def priority(instance), do: DeparturesNoData.priority(instance)
    def serialize(instance), do: DeparturesNoData.serialize(instance)
    def slot_names(instance), do: DeparturesNoData.slot_names(instance)
    def widget_type(instance), do: DeparturesNoData.widget_type(instance)
    def valid_candidate?(instance), do: DeparturesNoData.valid_candidate?(instance)
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: 0
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.DeparturesNoDataView
  end
end
