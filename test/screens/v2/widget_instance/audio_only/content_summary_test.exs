defmodule Screens.V2.WidgetInstance.AudioOnly.ContentSummaryTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias Screens.Config.Screen
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.AudioOnly.ContentSummary
  alias Screens.V2.WidgetInstance.MockWidget
  alias Screens.V2.WidgetInstance.{NormalHeader, ShuttleBusInfo}

  setup do
    pre_fare_config = struct(Screen, %{app_id: :pre_fare_v2})
    other_config = struct(Screen, %{app_id: :bus_e_ink_v2})

    instance_with_header = %ContentSummary{
      screen: nil,
      widgets_snapshot: [struct(NormalHeader)],
      lines_at_station: [:red, :orange]
    }

    instance_without_header = %ContentSummary{
      screen: nil,
      widgets_snapshot: [],
      lines_at_station: [:red, :orange]
    }

    instance_with_surge_widgets = %ContentSummary{
      screen: nil,
      widgets_snapshot: [struct(ShuttleBusInfo)],
      lines_at_station: []
    }

    instance_with_takeover_content = %ContentSummary{
      screen: nil,
      widgets_snapshot: [%MockWidget{slot_names: [:full_body]}],
      lines_at_station: [:red, :orange]
    }

    %{
      pre_fare_config: pre_fare_config,
      other_config: other_config,
      instance_with_header: instance_with_header,
      instance_without_header: instance_without_header,
      instance_with_takeover_content: instance_with_takeover_content,
      instance_with_surge_widgets: instance_with_surge_widgets
    }
  end

  defp put_config(instance, config), do: %{instance | screen: config}

  describe "audio_serialize/1" do
    test "returns map with lines_at_station for pre-fare screens", %{
      pre_fare_config: pre_fare_config,
      instance_with_header: widget
    } do
      widget = put_config(widget, pre_fare_config)

      expected_result = %{lines_at_station: [:red, :orange]}

      assert expected_result == WidgetInstance.audio_serialize(widget)
    end

    test "fails for other screen types", %{
      other_config: other_config,
      instance_with_header: widget
    } do
      widget = put_config(widget, other_config)

      assert_raise FunctionClauseError, fn -> WidgetInstance.audio_serialize(widget) end
    end
  end

  describe "audio_sort_key/1" do
    test "if a header widget is in widgets_snapshot, returns the header's audio_sort_key ++ [0]",
         %{
           pre_fare_config: pre_fare_config,
           instance_with_header: widget
         } do
      widget = put_config(widget, pre_fare_config)

      assert [0, 0] == WidgetInstance.audio_sort_key(widget)
    end

    test "if widgets_snapshot doesn't contain a header widget, logs a warning and returns [0]", %{
      pre_fare_config: pre_fare_config,
      instance_without_header: widget
    } do
      widget = put_config(widget, pre_fare_config)

      {result, log} = with_log(fn -> WidgetInstance.audio_sort_key(widget) end)

      assert [0] == result
      assert String.contains?(log, "Failed to find a header widget in the audio readout queue")
    end
  end

  describe "audio_valid_candidate?/1" do
    test "on pre-fare screens, widget is valid if there is no takeover content", %{
      pre_fare_config: pre_fare_config,
      instance_with_header: widget
    } do
      widget = put_config(widget, pre_fare_config)

      assert WidgetInstance.audio_valid_candidate?(widget)
    end

    test "on pre-fare screens, widget is not valid if there is any takeover content", %{
      pre_fare_config: pre_fare_config,
      instance_with_takeover_content: widget
    } do
      widget = put_config(widget, pre_fare_config)

      refute WidgetInstance.audio_valid_candidate?(widget)
    end

    test "widget is not valid on screens other than pre-fare", %{
      other_config: other_config,
      instance_with_takeover_content: widget
    } do
      widget = put_config(widget, other_config)

      refute WidgetInstance.audio_valid_candidate?(widget)
    end
  end

  describe "audio_view/1" do
    test "returns ContentSummaryView for instances without surge widgets", %{
      instance_with_header: widget
    } do
      assert ScreensWeb.V2.Audio.ContentSummaryView == WidgetInstance.audio_view(widget)
    end

    test "returns SurgeContentSummaryView for instances with surge widgets", %{
      instance_with_surge_widgets: widget
    } do
      assert ScreensWeb.V2.Audio.SurgeContentSummaryView == WidgetInstance.audio_view(widget)
    end
  end
end
