defmodule Screens.V2.WidgetInstance.AudioOnly.AlertsOutroTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias ScreensConfig.Screen
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.AudioOnly.AlertsOutro
  alias Screens.V2.WidgetInstance.{MockWidget, SubwayStatus, ReconstructedAlert}

  setup do
    pre_fare_config = struct(Screen, %{app_id: :pre_fare_v2})
    other_config = struct(Screen, %{app_id: :bus_e_ink_v2})

    subway_status = struct(SubwayStatus)
    alert = struct(ReconstructedAlert)

    other_widget = %MockWidget{
      slot_names: [:header],
      audio_sort_key: [0],
      audio_valid_candidate?: true
    }

    takeover_widget = %MockWidget{
      slot_names: [:full_body],
      audio_sort_key: [0],
      audio_valid_candidate?: true
    }

    audio_sort_key_fn = fn
      %MockWidget{} = mock_widget -> WidgetInstance.audio_sort_key(mock_widget)
      %SubwayStatus{} -> [1]
      %ReconstructedAlert{} -> [2]
    end

    instance_without_alert_widgets = %AlertsOutro{
      screen: nil,
      widgets_snapshot: [subway_status, other_widget]
    }

    instance_with_alerts = %AlertsOutro{
      screen: nil,
      widgets_snapshot: [subway_status, alert, other_widget]
    }

    instance_with_takeover_content = %AlertsOutro{
      screen: nil,
      widgets_snapshot: [takeover_widget, subway_status, alert, other_widget]
    }

    %{
      pre_fare_config: pre_fare_config,
      other_config: other_config,
      audio_sort_key_fn: audio_sort_key_fn,
      instance_without_alert_widgets: instance_without_alert_widgets,
      instance_with_alerts: instance_with_alerts,
      instance_with_takeover_content: instance_with_takeover_content
    }
  end

  defp put_config(widget, config), do: %{widget | screen: config}

  describe "audio_serialize/1" do
    test "returns an empty map for pre-fare", %{
      pre_fare_config: pre_fare_config,
      instance_with_alerts: widget
    } do
      widget = put_config(widget, pre_fare_config)

      assert %{} == WidgetInstance.audio_serialize(widget)
    end

    test "fails for other screen type", %{
      other_config: other_config,
      instance_with_alerts: widget
    } do
      widget = put_config(widget, other_config)

      assert_raise FunctionClauseError, fn -> WidgetInstance.audio_serialize(widget) end
    end
  end

  describe "audio_sort_key/1" do
    # NOTE: need to call `AlertsOutro.audio_sort_key/2` in order to inject a stubbed function for testing purposes.
    # This is otherwise equivalent to `WidgetInstance.audio_sort_key/1`.
    test "returns audio sort key ++ [2] of last alert widget in the readout queue",
         %{audio_sort_key_fn: audio_sort_key_fn, instance_with_alerts: widget} do
      assert [2, 2] == AlertsOutro.audio_sort_key(widget, audio_sort_key_fn)
    end

    test "logs a warning and returns [100] if there's no alert widget in the readout queue",
         %{audio_sort_key_fn: audio_sort_key_fn, instance_without_alert_widgets: widget} do
      {result, log} = with_log(fn -> AlertsOutro.audio_sort_key(widget, audio_sort_key_fn) end)

      assert [100] == result
      assert log =~ "alerts_outro_widget_not_found"
    end
  end

  describe "audio_valid_candidate?/1" do
    test "for pre-fare, returns true if there's at least one alert widget and no takeover content",
         %{
           pre_fare_config: pre_fare_config,
           instance_with_alerts: widget
         } do
      widget = put_config(widget, pre_fare_config)

      assert WidgetInstance.audio_valid_candidate?(widget)
    end

    test "for pre-fare, returns false if there's no alert widget",
         %{
           pre_fare_config: pre_fare_config,
           instance_without_alert_widgets: widget
         } do
      widget = put_config(widget, pre_fare_config)

      refute WidgetInstance.audio_valid_candidate?(widget)
    end

    test "returns false for other screen type",
         %{
           other_config: other_config,
           instance_with_alerts: widget
         } do
      widget = put_config(widget, other_config)

      refute WidgetInstance.audio_valid_candidate?(widget)
    end
  end
end
