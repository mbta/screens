defmodule Screens.V2.WidgetInstance.AlertTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance.Alert
  alias Screens.Alerts.Alert, as: ApiAlert

  setup_all do
    delay_widget = %Alert{
      screen: :ok,
      alert: %ApiAlert{effect: :delay}
    }

    closure_widget = %Alert{
      screen: :ok,
      alert: %ApiAlert{effect: :stop_closure}
    }

    other_widget = %Alert{
      screen: :ok,
      alert: %ApiAlert{effect: :unknown}
    }

    [
      delay_widget: delay_widget,
      closure_widget: closure_widget,
      other_widget: other_widget
    ]
  end

  describe "priority/1" do
    test "always gives a base priority of 1", ctx do
      dummy_fn = fn _ -> 0 end

      expected_base_priority = 1

      assert [^expected_base_priority | _] =
               Alert.priority(ctx.delay_widget, dummy_fn, dummy_fn, dummy_fn)

      assert [^expected_base_priority | _] =
               Alert.priority(ctx.closure_widget, dummy_fn, dummy_fn, dummy_fn)

      assert [^expected_base_priority | _] =
               Alert.priority(ctx.other_widget, dummy_fn, dummy_fn, dummy_fn)
    end

    test "uses active priority, then informed entity priority, then effect priority", %{
      delay_widget: widget
    } do
      pid = self()

      expected_base_priority = 1
      expected_ap = 10
      expected_iep = 20
      expected_ep = 30

      expected = [expected_base_priority, expected_ap, expected_iep, expected_ep]

      ap_fn = fn _ ->
        send(pid, :called_active)
        expected_ap
      end

      iep_fn = fn _ ->
        send(pid, :called_informed_entity)
        expected_iep
      end

      ep_fn = fn _ ->
        send(pid, :called_effect)
        expected_ep
      end

      assert expected == Alert.priority(widget, ap_fn, iep_fn, ep_fn)

      assert_received :called_active
      assert_received :called_informed_entity
      assert_received :called_effect
    end
  end

  describe "serialize/1" do
    test "serializes the alert", %{delay_widget: widget} do
      alert_active? = fn _ -> true end

      expected = %{
        pill: :bus,
        icon: :warning,
        active_status: :active,
        header: "Dummy alert header",
        text: ["Dummy alert text"]
      }

      assert expected == Alert.serialize(widget, alert_active?)
    end
  end

  describe "slot_names/1" do
    test "returns medium-size slot names", %{delay_widget: widget} do
      assert ~w[medium_left medium_right]a == Alert.slot_names(widget)
    end
  end

  describe "active_priority/1" do
    test "returns higher priority for active alerts", %{delay_widget: widget} do
      yes_active = fn _ -> true end
      no_active = fn _ -> false end

      assert Alert.active_priority(widget, yes_active) < Alert.active_priority(widget, no_active)
    end
  end

  describe "informed_entity_priority/1" do
    test "returns 0", %{delay_widget: widget} do
      assert 0 == Alert.informed_entity_priority(widget)
    end
  end

  describe "effect_priority/1" do
    test "returns lower priority for delays", %{delay_widget: widget} do
      assert 1 == Alert.effect_priority(widget)
    end

    test "returns higher priority for stop closures", %{closure_widget: widget} do
      assert 0 == Alert.effect_priority(widget)
    end

    test "returns lowest priority for effects we don't know how to handle well", %{
      other_widget: widget
    } do
      assert 100 == Alert.effect_priority(widget)
    end
  end
end
