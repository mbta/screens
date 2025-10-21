defmodule Screens.Elevator.Closure do
  @moduledoc """
  Combines an alert representing an elevator closure with hand-authored data about that elevator.
  """

  alias Screens.Alerts.Alert
  alias Screens.Facilities.Facility
  alias Screens.{Elevator, Report}

  import Screens.Inject
  @elevator injected(Elevator)

  @enforce_keys ~w[alert elevator facility]a
  defstruct @enforce_keys

  @type t :: %__MODULE__{alert: Alert.t(), elevator: Elevator.t() | nil, facility: Facility.t()}

  @spec from_alert(Alert.t()) :: {:ok, t()} | :error
  def from_alert(%Alert{effect: :elevator_closure, informed_entities: entities} = alert) do
    # We expect there is a 1:1 relationship between `elevator_closure` alerts and individual
    # out-of-service elevators. Log a warning if our assumptions don't hold.
    facilities = entities |> Enum.map(& &1.facility) |> Enum.reject(&is_nil/1) |> Enum.uniq()

    case facilities do
      [] ->
        :error

      [%Facility{id: id} = facility] ->
        {:ok, %__MODULE__{alert: alert, elevator: @elevator.get(id), facility: facility}}

      _multiple ->
        Report.warning("elevator_closure_affects_multiple", alert_id: alert.id)
        :error
    end
  end

  def from_alert(_alert), do: :error
end
