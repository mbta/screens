defmodule Screens.V2.WidgetInstance.DupSpecialCaseAlert do
  @moduledoc """
  A mostly logic-less widget that displays a "special case" alert on a DUP screen.

  This widget should always serialize the same as the DupAlert widget:
  Its serialized data must be valid for a DUP full-screen or partial alert on the client.
  """

  @enforce_keys [:serialize_map, :slot_names, :widget_type, :rotation_index]
  defstruct @enforce_keys

  def slot_names(%__MODULE__{} = t) do
    Enum.map(t.slot_names, &:"#{&1}_#{t.rotation_index}")
  end

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.DupSpecialCaseAlert

    def priority(_t), do: [1, 2]
    def serialize(t), do: t.serialize_map
    def slot_names(t), do: DupSpecialCaseAlert.slot_names(t)
    def widget_type(t), do: t.widget_type
    def valid_candidate?(_t), do: true
    def audio_serialize(_t), do: %{}
    def audio_sort_key(_t), do: [0]
    def audio_valid_candidate?(_t), do: false
    def audio_view(_t), do: nil
  end
end
