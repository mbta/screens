defmodule Screens.V2.WidgetInstance.AudioOnly.AlertsIntroTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias Screens.Config.Screen
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.AudioOnly.AlertsIntro
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

    slot_names_fn = fn
      %MockWidget{} = mock_widget -> WidgetInstance.slot_names(mock_widget)
      %SubwayStatus{} -> [:large]
      %ReconstructedAlert{} -> [:large]
    end

    instance_without_service_alert_widgets = %AlertsIntro{
      screen: nil,
      widgets_snapshot: [other_widget]
    }

    instance_with_subway_status_and_alerts = %AlertsIntro{
      screen: nil,
      widgets_snapshot: [subway_status, alert, other_widget]
    }

    instance_with_alert_at_start = %AlertsIntro{
      screen: nil,
      widgets_snapshot: [subway_status, alert]
    }

    instance_with_takeover_content = %AlertsIntro{
      screen: nil,
      widgets_snapshot: [takeover_widget, subway_status, alert, other_widget]
    }

    %{
      pre_fare_config: pre_fare_config,
      other_config: other_config,
      audio_sort_key_fn: audio_sort_key_fn,
      slot_names_fn: slot_names_fn,
      instance_without_service_alert_widgets: instance_without_service_alert_widgets,
      instance_with_subway_status_and_alerts: instance_with_subway_status_and_alerts,
      instance_with_alert_at_start: instance_with_alert_at_start,
      instance_with_takeover_content: instance_with_takeover_content
    }
  end

  defp put_config(widget, config), do: %{widget | screen: config}

  describe "audio_serialize/1" do
    test "returns an empty map for pre-fare", %{
      pre_fare_config: pre_fare_config,
      instance_with_subway_status_and_alerts: widget
    } do
      widget = put_config(widget, pre_fare_config)

      assert %{} == WidgetInstance.audio_serialize(widget)
    end

    test "fails for other screen type", %{
      other_config: other_config,
      instance_with_subway_status_and_alerts: widget
    } do
      widget = put_config(widget, other_config)

      assert_raise FunctionClauseError, fn -> WidgetInstance.audio_serialize(widget) end
    end
  end

  describe "audio_sort_key/1" do
    # NOTE: need to call `AlertsIntro.audio_sort_key/2` in order to inject a stubbed function for testing purposes.
    # This is otherwise equivalent to `WidgetInstance.audio_sort_key/1`.

    test "returns audio sort key ++ [1] of widget immediately preceding first service alert widget in the readout queue",
         %{audio_sort_key_fn: audio_sort_key_fn, instance_with_subway_status_and_alerts: widget} do
      assert [0, 1] == AlertsIntro.audio_sort_key(widget, audio_sort_key_fn)
    end

    test "logs a warning and returns [0] if there's no service alert widget in the readout queue",
         %{audio_sort_key_fn: audio_sort_key_fn, instance_without_service_alert_widgets: widget} do
      {result, log} = with_log(fn -> AlertsIntro.audio_sort_key(widget, audio_sort_key_fn) end)

      assert [0] == result

      assert String.contains?(
               log,
               "Failed to find a service alert widget in the audio readout queue"
             )
    end

    test "logs a warning and returns [0] if service alert widget is first in the readout queue",
         %{audio_sort_key_fn: audio_sort_key_fn, instance_with_alert_at_start: widget} do
      {result, log} = with_log(fn -> AlertsIntro.audio_sort_key(widget, audio_sort_key_fn) end)

      assert [0] == result

      assert String.contains?(
               log,
               "Unexpectedly found a service alert widget at the start of the audio readout queue"
             )
    end
  end

  describe "audio_valid_candidate?/1" do
    # NOTE: need to call `AlertsIntro.audio_valid_candidate?/2` in order to inject a stubbed function
    # for testing purposes. This is otherwise equivalent to `WidgetInstance.audio_valid_candidate?/1`.

    test "for pre-fare, returns true if there's at least one service alert widget and no takeover content",
         %{
           slot_names_fn: slot_names_fn,
           pre_fare_config: pre_fare_config,
           instance_with_subway_status_and_alerts: widget
         } do
      widget = put_config(widget, pre_fare_config)

      assert AlertsIntro.audio_valid_candidate?(widget, slot_names_fn)
    end

    test "for pre-fare, returns false if there's no service alert widget",
         %{
           slot_names_fn: slot_names_fn,
           pre_fare_config: pre_fare_config,
           instance_without_service_alert_widgets: widget
         } do
      widget = put_config(widget, pre_fare_config)

      refute AlertsIntro.audio_valid_candidate?(widget, slot_names_fn)
    end

    test "for pre-fare, returns false if there's any takeover content",
         %{
           slot_names_fn: slot_names_fn,
           pre_fare_config: pre_fare_config,
           instance_with_takeover_content: widget
         } do
      widget = put_config(widget, pre_fare_config)

      refute AlertsIntro.audio_valid_candidate?(widget, slot_names_fn)
    end

    test "returns false for other screen type",
         %{
           slot_names_fn: slot_names_fn,
           other_config: other_config,
           instance_with_subway_status_and_alerts: widget
         } do
      widget = put_config(widget, other_config)

      refute AlertsIntro.audio_valid_candidate?(widget, slot_names_fn)
    end
  end
end
