defmodule Screens.V2.WidgetInstance.AlertTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance.AlertOld, as: AlertWidget
  alias Screens.Alerts.Alert

  describe "priority/1" do
    test "always gives a base priority of 1" do
      delay_widget = alert_widget_with_effect(:delay)
      closure_widget = alert_widget_with_effect(:stop_closure)
      other_widget = alert_widget_with_effect(:unknown)

      alert_active? = fn _ -> true end

      expected_base_priority = 1

      assert [^expected_base_priority | _] = AlertWidget.priority(delay_widget, alert_active?)
      assert [^expected_base_priority | _] = AlertWidget.priority(closure_widget, alert_active?)
      assert [^expected_base_priority | _] = AlertWidget.priority(other_widget, alert_active?)
    end

    test "returns higher priority for active alerts" do
      widget = alert_widget_with_effect(:delay)

      yes_active = fn _ -> true end
      no_active = fn _ -> false end

      assert AlertWidget.priority(widget, yes_active) < AlertWidget.priority(widget, no_active)
    end

    test "returns lower priority for delays" do
      closure_widget = alert_widget_with_effect(:stop_closure)
      delay_widget = alert_widget_with_effect(:delay)

      alert_active? = fn _ -> true end

      assert AlertWidget.priority(closure_widget, alert_active?) <
               AlertWidget.priority(delay_widget, alert_active?)
    end

    test "returns lowest priority for effects we don't know how to handle well" do
      delay_widget = alert_widget_with_effect(:delay)
      other_widget = alert_widget_with_effect(:unknown)

      alert_active? = fn _ -> true end

      assert AlertWidget.priority(delay_widget, alert_active?) <
               AlertWidget.priority(other_widget, alert_active?)
    end
  end

  describe "serialize/1" do
    test "serializes the alert" do
      widget = alert_widget_with_effect(:delay)

      alert_active? = fn _ -> true end

      expected = %{
        pill: :bus,
        icon: :warning,
        active_status: :active,
        header: "Dummy alert header",
        text: ["Dummy alert text"]
      }

      assert expected == AlertWidget.serialize(widget, alert_active?)
    end
  end

  describe "slot_names/1" do
    test "returns medium-size slot names" do
      widget = alert_widget_with_effect(:delay)

      assert ~w[medium_left medium_right]a == AlertWidget.slot_names(widget)
    end
  end

  describe "widget_type/1" do
    test "returns alert widget type" do
      widget = alert_widget_with_effect(:delay)

      assert :alert == AlertWidget.widget_type(widget)
    end
  end

  defp alert_widget_with_effect(effect) do
    %AlertWidget{
      screen: :ok,
      alert: %Alert{effect: effect}
    }
  end
end
