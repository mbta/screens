defmodule Screens.V2.WidgetInstance.ElevatorStatusNew do
  @moduledoc false

  alias Screens.Elevator.Closure

  @enforce_keys ~w[closures]a
  defstruct @enforce_keys

  @type t :: %__MODULE__{closures: [Closure.t()]}

  def serialize(%__MODULE__{}) do
    %{}
  end

  defimpl Screens.V2.AlertsWidget do
    def alert_ids(_instance), do: []
  end

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.ElevatorStatusNew

    def priority(_instance), do: [2]
    def serialize(instance), do: ElevatorStatusNew.serialize(instance)
    def slot_names(_instance), do: [:lower_right]
    def widget_type(_instance), do: :elevator_status_new
    def valid_candidate?(_instance), do: true
    def audio_serialize(instance), do: ElevatorStatusNew.serialize(instance)
    def audio_sort_key(_instance), do: [4]
    def audio_valid_candidate?(_instance), do: true
    def audio_view(_instance), do: ScreensWeb.V2.Audio.ElevatorStatusNewView
  end
end
