defmodule Screens.V2.WidgetInstance.OvernightCRDeparturesTest do
  use ExUnit.Case, async: true
  alias Screens.V2.WidgetInstance
  alias Screens.Config.Screen
  alias Screens.Schedules.Schedule

  setup do
    %{
      inbound_widget: %WidgetInstance.OvernightCRDepartures{
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil},
        direction_to_destination: 1,
        last_tomorrow_schedule:
          struct(Schedule, %{departure_time: ~U[2022-01-02T21:00:00Z], stop_headsign: "Test Stop"}),
        priority: [0],
        now: ~U[2022-01-01T08:00:00Z]
      },
      outbound_widget: %WidgetInstance.OvernightCRDepartures{
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil},
        direction_to_destination: 0,
        last_tomorrow_schedule:
          struct(Schedule, %{departure_time: ~U[2022-01-02T21:00:00Z], stop_headsign: "Test Stop"}),
        priority: [0],
        now: ~U[2022-01-01T08:00:00Z]
      }
    }
  end

  describe "priority/1" do
    test "returns priority defined on struct", %{inbound_widget: widget} do
      assert [0] == WidgetInstance.priority(widget)
    end
  end

  describe "serialize/1" do
    test "returns inbound, last_schedule_departure_time, and last_schedule_headsign", %{
      inbound_widget: widget
    } do
      %{departure_time: departure_time} = widget.last_tomorrow_schedule
      shifted_datetime = DateTime.shift_zone!(departure_time, "America/New_York")

      assert %{
               direction: "inbound",
               last_schedule_departure_time: shifted_datetime,
               last_schedule_headsign: "Test Stop"
             } == WidgetInstance.serialize(widget)
    end

    test "returns outbound, last_schedule_departure_time, and last_schedule_headsign", %{
      outbound_widget: widget
    } do
      %{departure_time: departure_time} = widget.last_tomorrow_schedule
      shifted_datetime = DateTime.shift_zone!(departure_time, "America/New_York")

      assert %{
               direction: "outbound",
               last_schedule_departure_time: shifted_datetime,
               last_schedule_headsign: "Test Stop"
             } == WidgetInstance.serialize(widget)
    end
  end

  describe "slot_names/1" do
    test "returns main_content_left", %{inbound_widget: widget} do
      assert [:main_content_left] == WidgetInstance.slot_names(widget)
    end
  end

  describe "widget_type/1" do
    test "returns overnight_cr_departures", %{inbound_widget: widget} do
      assert :overnight_cr_departures == WidgetInstance.widget_type(widget)
    end
  end

  describe "audio_serialize/1" do
    test "returns empty string", %{inbound_widget: widget} do
      assert %{} == WidgetInstance.audio_serialize(widget)
    end
  end

  describe "audio_sort_key/1" do
    test "returns [0]", %{inbound_widget: widget} do
      assert [0] == WidgetInstance.audio_sort_key(widget)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false", %{inbound_widget: widget} do
      refute WidgetInstance.audio_valid_candidate?(widget)
    end
  end

  describe "audio_view/1" do
    test "returns OvernightCRDeparturesView", %{inbound_widget: widget} do
      assert ScreensWeb.V2.Audio.OvernightCRDeparturesView ==
               WidgetInstance.audio_view(widget)
    end
  end
end
