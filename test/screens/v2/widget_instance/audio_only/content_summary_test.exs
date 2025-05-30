defmodule Screens.V2.WidgetInstance.AudioOnly.ContentSummaryTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.AudioOnly.ContentSummary
  alias Screens.V2.WidgetInstance.Departures.NormalSection
  alias Screens.V2.WidgetInstance.NormalHeader
  alias ScreensConfig.{Header, Screen}
  alias ScreensConfig.Screen.PreFare

  setup do
    pre_fare_config =
      struct(Screen, %{
        app_id: :pre_fare_v2,
        app_params: struct(PreFare, %{header: %Header.StopId{stop_id: "place-test"}})
      })

    departures_config =
      struct(Screen, %{
        app_id: :pre_fare_v2,
        app_params:
          struct(PreFare, %{
            header: %Header.StopId{stop_id: "place-test-departures"},
            departures: %ScreensConfig.Departures{sections: [%NormalSection{}]}
          })
      })

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

    %{
      pre_fare_config: pre_fare_config,
      departures_config: departures_config,
      other_config: other_config,
      instance_with_header: instance_with_header,
      instance_without_header: instance_without_header
    }
  end

  defp put_config(instance, config), do: %{instance | screen: config}

  defp put_stop_id(widget, stop_id) do
    %{
      widget
      | screen: %{
          widget.screen
          | app_params: %{widget.screen.app_params | header: %Header.StopId{stop_id: stop_id}}
        }
    }
  end

  describe "audio_serialize/1" do
    test "returns map with lines_at_station for pre-fare screens", %{
      pre_fare_config: pre_fare_config,
      instance_with_header: widget
    } do
      widget = put_config(widget, pre_fare_config)

      expected_result = %{lines_at_station: [:red, :orange], has_departures: false}

      assert expected_result == WidgetInstance.audio_serialize(widget)
    end

    test "returns has_departures true with lines_at_station for pre-fare screens", %{
      departures_config: departures_config,
      instance_with_header: widget
    } do
      widget = put_config(widget, departures_config)

      expected_result = %{lines_at_station: [:red, :orange], has_departures: true}

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
      assert log =~ "content_summary_header_not_found"
    end
  end

  describe "audio_valid_candidate?/1" do
    test "widget is valid on pre-fare screens",
         %{pre_fare_config: pre_fare_config, instance_with_header: widget} do
      widget = widget |> put_config(pre_fare_config) |> put_stop_id("place-gover")

      assert WidgetInstance.audio_valid_candidate?(widget)
    end

    test "widget is not valid on screens other than pre-fare",
         %{other_config: other_config, instance_with_header: widget} do
      widget = put_config(widget, other_config)

      refute WidgetInstance.audio_valid_candidate?(widget)
    end
  end

  describe "audio_view/1" do
    test "returns ContentSummaryView", %{instance_with_header: widget} do
      assert ScreensWeb.V2.Audio.ContentSummaryView == WidgetInstance.audio_view(widget)
    end
  end
end
