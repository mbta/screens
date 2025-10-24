defmodule Screens.V2.WidgetInstance.ElevatorStatusNew do
  @moduledoc false

  alias Screens.Elevator.Closure
  alias Screens.Stops.Stop

  @enforce_keys ~w[closures station_id]a
  defstruct @enforce_keys

  @type t :: %__MODULE__{closures: [Closure.t()], station_id: Stop.id()}

  @typep serialized ::
           %{
             layout: :all_ok,
             with_backups: boolean()
           }
           | %{
               layout: :all_ok_with_alternatives,
               count: pos_integer()
             }
           | %{
               layout: :closed_elsewhere,
               station_names: [String.t()],
               other_closures_count: non_neg_integer(),
               other_closures_without_alternatives_count: non_neg_integer()
             }
           | %{
               layout: :closed_here,
               elevator_names: [String.t()],
               station_id: String.t()
             }

  def serialize(%__MODULE__{closures: closures, station_id: station_id}) do
    # Enum.find_value(@cases, %{}, & &1.(closures, station_id))
    %{
      layout: :closed_here,
      elevator_names: [
        "Copley Elevator 977 (Kenmore & West platform to Boylston St)",
        "Copley Elevator 977 (Kenmore & West platform to Boylston St)"
      ],
      station_id: station_id,
      summary: "Do something about it."
    }
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
