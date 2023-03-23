defmodule Screens.V2.WidgetInstance.DupSpecialCaseAlert do
  @moduledoc """
  A mostly logic-less widget that displays a "special case" alert on a DUP screen.

  This widget should always serialize the same as the DupAlert widget:
  Its serialized data must be valid for a DUP full-screen or partial alert on the client.
  """

  alias Screens.V2.WidgetInstance

  @enforce_keys [:alert_ids, :serialize_map, :slot_names, :widget_type]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          # IDs of alert(s) represented by this widget, so that we can properly report
          # to ScreensByAlert
          alert_ids: list(alert_id),
          serialize_map: map(),
          slot_names: list(WidgetInstance.slot_id()),
          widget_type: WidgetInstance.widget_type()
        }

  @type alert_id :: String.t()

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.DupSpecialCaseAlert

    def priority(_t), do: [1, 2]
    def serialize(t), do: t.serialize_map
    def slot_names(t), do: t.slot_names
    def widget_type(t), do: t.widget_type
    def valid_candidate?(_t), do: true
    def audio_serialize(_t), do: %{}
    def audio_sort_key(_t), do: [0]
    def audio_valid_candidate?(_t), do: false
    def audio_view(_t), do: nil
  end

  defimpl Screens.V2.AlertsWidget do
    def alert_ids(instance), do: instance.alert_ids
  end
end
