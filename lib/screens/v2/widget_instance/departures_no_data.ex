defmodule Screens.V2.WidgetInstance.DeparturesNoData do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.Alerts

  defstruct screen: nil, show_alternatives?: nil, slot_name: nil

  @type t :: %__MODULE__{
          screen: Screens.Config.Screen.t(),
          show_alternatives?: boolean(),
          slot_name: atom()
        }

  def priority(_instance), do: [2]

  def serialize(%__MODULE__{} = instance) do
    %{
      show_alternatives: instance.show_alternatives?,
      stop_id: stop_id(instance)
    }
  end

  def slot_names(%__MODULE__{slot_name: slot_name}) when not is_nil(slot_name),
    do: [slot_name]

  def slot_names(%__MODULE__{screen: %Screen{app_id: :gl_eink_v2}}), do: [:full_main_content]
  def slot_names(_instance), do: [:main_content]
  def widget_type(_instance), do: :departures_no_data
  def valid_candidate?(_instance), do: true

  defp stop_id(%__MODULE__{
         screen: %Screen{app_params: %_app{alerts: %Alerts{stop_id: stop_id}}}
       }) do
    stop_id
  end

  defp stop_id(_), do: nil

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.DeparturesNoData

    def priority(instance), do: DeparturesNoData.priority(instance)
    def serialize(instance), do: DeparturesNoData.serialize(instance)
    def slot_names(instance), do: DeparturesNoData.slot_names(instance)
    def widget_type(instance), do: DeparturesNoData.widget_type(instance)
    def valid_candidate?(instance), do: DeparturesNoData.valid_candidate?(instance)
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.DeparturesNoDataView
  end
end
