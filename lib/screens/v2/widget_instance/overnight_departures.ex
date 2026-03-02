defmodule Screens.V2.WidgetInstance.OvernightDepartures do
  @moduledoc false
  alias Screens.V2.WidgetInstance.Serializer.RoutePill

  defstruct screen: nil, slot_names: [], routes: []

  @type t :: %__MODULE__{slot_names: list(atom()), routes: list(atom())}

  def serialize(%__MODULE__{routes: routes}) do
    %{routes: Enum.map(routes, &RoutePill.serialize_icon/1)}
  end

  def slot_names(%__MODULE__{slot_names: slot_names}) when length(slot_names) > 0,
    do: slot_names

  def slot_names(_instance), do: [:full_screen]

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.OvernightDepartures

    def priority(_instance), do: [1]
    def serialize(instance), do: OvernightDepartures.serialize(instance)
    def slot_names(instance), do: OvernightDepartures.slot_names(instance)
    def page_groups(_instance), do: []
    def widget_type(_instance), do: :overnight_departures
    def valid_candidate?(_instance), do: true
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.NullView
  end
end
