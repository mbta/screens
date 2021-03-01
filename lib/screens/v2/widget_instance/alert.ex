defmodule Screens.V2.WidgetInstance.Alert do
  @moduledoc false

  alias Screens.Alerts.Alert

  alias __MODULE__, as: T

  defstruct screen: :ok,
            alert: nil

  @type config :: :ok

  @type t :: %T{
          screen: config(),
          alert: Alert.t()
        }

  @base_alert_priority 1

  @effect_priorities cancellation: 0,
                     delay: 1,
                     detour: 0,
                     no_service: 0,
                     shuttle: 0,
                     suspension: 0,
                     station_closure: 0,
                     stop_closure: 0,
                     stop_moved: 0

  def priority(
        %T{} = t,
        active_priority_fn \\ &active_priority/1,
        informed_entity_priority_fn \\ &informed_entity_priority/1,
        effect_priority_fn \\ &effect_priority/1
      ) do
    [
      @base_alert_priority,
      active_priority_fn.(t),
      informed_entity_priority_fn.(t),
      effect_priority_fn.(t)
    ]
  end

  def serialize(%T{} = t, alert_active? \\ &Alert.happening_now?/1) do
    %{
      pill: :bus,
      icon: :warning,
      active_status: if(alert_active?.(t.alert), do: :active, else: :upcoming),
      header: serialize_header(t),
      text: serialize_text(t)
    }
  end

  def slot_names(%T{}), do: ~w[medium_left medium_right]a

  def active_priority(%T{alert: alert}, alert_active? \\ &Alert.happening_now?/1) do
    if alert_active?.(alert), do: 0, else: 1
  end

  def informed_entity_priority(%T{
        screen: :ok,
        alert: %Alert{informed_entities: _informed_entities}
      }) do
    0
  end

  for {effect, priority} <- @effect_priorities do
    def effect_priority(%T{alert: %Alert{effect: unquote(effect)}}) do
      unquote(priority)
    end
  end

  def effect_priority(_), do: 100

  defp serialize_text(%T{alert: _alert}) do
    ["Dummy alert text"]
  end

  defp serialize_header(%T{alert: _alert}) do
    "Dummy alert header"
  end

  defimpl Screens.V2.WidgetInstance do
    def priority(%T{} = t) do
      T.priority(t)
    end

    def serialize(%T{} = t) do
      T.serialize(t)
    end

    def slot_names(%T{} = t) do
      T.slot_names(t)
    end
  end
end
