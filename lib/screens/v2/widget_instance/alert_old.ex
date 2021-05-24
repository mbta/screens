defmodule Screens.V2.WidgetInstance.AlertOld do
  @moduledoc false

  alias Screens.Alerts.Alert

  alias __MODULE__, as: T

  defstruct screen: nil,
            alert: nil

  @type config :: Screens.V2.ScreenData.config()

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

  def priority(%T{} = t, alert_active? \\ &Alert.happening_now?/1) do
    [
      @base_alert_priority,
      active_priority(t, alert_active?),
      informed_entity_priority(t),
      effect_priority(t)
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

  def widget_type(%T{}), do: :alert

  defp active_priority(%T{alert: alert}, alert_active?) do
    if alert_active?.(alert), do: 0, else: 1
  end

  defp informed_entity_priority(%T{
         screen: :ok,
         alert: %Alert{informed_entities: _informed_entities}
       }) do
    0
  end

  for {effect, priority} <- @effect_priorities do
    defp effect_priority(%T{alert: %Alert{effect: unquote(effect)}}) do
      unquote(priority)
    end
  end

  defp effect_priority(_), do: 100

  defp serialize_text(%T{alert: _alert}) do
    ["Dummy alert text"]
  end

  defp serialize_header(%T{alert: _alert}) do
    "Dummy alert header"
  end

  defimpl Screens.V2.WidgetInstance do
    def priority(t), do: T.priority(t)
    def serialize(t), do: T.serialize(t)
    def slot_names(t), do: T.slot_names(t)
    def widget_type(t), do: T.widget_type(t)
  end
end
