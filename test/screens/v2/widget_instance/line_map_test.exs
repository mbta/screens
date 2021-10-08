defmodule Screens.V2.WidgetInstance.LineMapTest do
  use ExUnit.Case, async: true

  alias Screens.Predictions.Prediction
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.V2.{Departure, WidgetInstance}
  alias Screens.V2.WidgetInstance.LineMap
  alias Screens.Vehicles.Vehicle

  setup do
    stops = [
      %Stop{id: "70238", name: "Cleveland Circle"},
      %Stop{id: "70236", name: "Englewood Avenue"},
      %Stop{id: "70234", name: "Dean Road"},
      %Stop{id: "70232", name: "Tappan Street"},
      %Stop{id: "70230", name: "Washington Square"},
      %Stop{id: "70200", name: "Park Street"},
      %Stop{id: "70201", name: "Government Center"},
      %Stop{id: "70203", name: "Haymarket"},
      %Stop{id: "70205", name: "North Station"}
    ]

    %{stops: stops}
  end

  describe "priority/1" do
    test "returns 2" do
      instance = %LineMap{}
      assert [2] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize_stops/2" do
    test "returns past stops and up two future stops in order", %{stops: stops} do
      assert [
               %{current: false, downstream: true, label: "Government Center", terminal: false},
               %{current: false, downstream: true, label: "Park Street", terminal: false},
               %{current: true, downstream: false, label: "Washington Square", terminal: false},
               %{current: false, downstream: false, label: "Tappan Street", terminal: false},
               %{current: false, downstream: false, label: "Dean Road", terminal: false},
               %{current: false, downstream: false, label: "Englewood Avenue", terminal: false},
               %{current: false, downstream: false, label: "Cleveland Circle", terminal: true}
             ] == LineMap.serialize_stops("70230", stops)
    end

    test "handles fewer than two future stops", %{stops: stops} do
      assert [
               %{current: false, downstream: true, label: "North Station", terminal: true},
               %{current: true, downstream: false, label: "Haymarket", terminal: false},
               %{current: false, downstream: false, label: "Government Center", terminal: false},
               %{current: false, downstream: false, label: "Park Street", terminal: false},
               %{current: false, downstream: false, label: "Washington Square", terminal: false},
               %{current: false, downstream: false, label: "Tappan Street", terminal: false},
               %{current: false, downstream: false, label: "Dean Road", terminal: false},
               %{current: false, downstream: false, label: "Englewood Avenue", terminal: false},
               %{current: false, downstream: false, label: "Cleveland Circle", terminal: true}
             ] == LineMap.serialize_stops("70203", stops)
    end
  end

  describe "serialize_vehicles/5" do
    test "filters irrelevant departures", %{stops: stops} do
      d1 = %Departure{prediction: nil}
      d2 = %Departure{prediction: %Prediction{vehicle: nil}}
      d3 = %Departure{prediction: %Prediction{vehicle: %Vehicle{direction_id: 1}}}
      departures = [d1, d2, d3]

      direction_id = 0
      current_stop = "70230"
      now = ~U[2020-01-01T02:00:00Z]

      assert [] == LineMap.serialize_vehicles(departures, stops, direction_id, current_stop, now)
    end

    test "correctly computes indexes of relevant departures", %{stops: stops} do
      direction_id = 0
      current_stop = "70230"
      now = ~U[2020-01-01T02:00:00Z]

      v = %Vehicle{id: "1", current_status: :stopped_at, stop_id: "70236", direction_id: 0}

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:02:00Z], vehicle: v}
      }

      assert [%{index: 5.0}] =
               LineMap.serialize_vehicles([d], stops, direction_id, current_stop, now)

      v = %Vehicle{v | stop_id: "70203"}

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:02:00Z], vehicle: v}
      }

      assert [] == LineMap.serialize_vehicles([d], stops, direction_id, current_stop, now)

      v = %Vehicle{v | stop_id: "70238"}

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:02:00Z], vehicle: v}
      }

      assert [%{index: 6.0}] =
               LineMap.serialize_vehicles([d], stops, direction_id, current_stop, now)

      v = %Vehicle{v | current_status: :in_transit_to}

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:02:00Z], vehicle: v}
      }

      assert [%{index: 6.0}] =
               LineMap.serialize_vehicles([d], stops, direction_id, current_stop, now)

      v = %Vehicle{v | stop_id: "70230"}

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:02:00Z], vehicle: v}
      }

      assert [%{index: 2.7}] =
               LineMap.serialize_vehicles([d], stops, direction_id, current_stop, now)
    end

    test "correctly serializes labels", %{stops: stops} do
      direction_id = 0
      current_stop = "70230"
      now = ~U[2020-01-01T02:00:00Z]

      v = %Vehicle{id: "1", current_status: :stopped_at, stop_id: "70236", direction_id: 0}

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:02:00Z], vehicle: v}
      }

      assert [%{id: "1", label: %{type: :minutes, minutes: 2}}] =
               LineMap.serialize_vehicles([d], stops, direction_id, current_stop, now)

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:00:30Z], vehicle: v}
      }

      assert [%{id: "1", label: %{type: :text, text: "Now"}}] =
               LineMap.serialize_vehicles([d], stops, direction_id, current_stop, now)
    end

    test "doesn't label departed vehicles", %{stops: stops} do
      direction_id = 0
      current_stop = "70230"
      now = ~U[2020-01-01T02:00:00Z]

      v = %Vehicle{id: "1", current_status: :stopped_at, stop_id: "70200", direction_id: 0}

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:02:00Z], vehicle: v}
      }

      assert [%{id: "1", label: nil}] =
               LineMap.serialize_vehicles([d], stops, direction_id, current_stop, now)
    end
  end

  describe "serialize_scheduled_departure/2" do
    test "returns nil when there are two or more predictions", %{stops: stops} do
      d1 = %Departure{prediction: %Prediction{}}
      d2 = %Departure{prediction: %Prediction{}}

      d3 = %Departure{
        prediction: nil,
        schedule: %Schedule{departure_time: ~U[2020-01-01T02:20:00Z]}
      }

      assert nil == LineMap.serialize_scheduled_departure([d1, d2, d3], stops)
      assert not is_nil(LineMap.serialize_scheduled_departure([d1, d3], stops))
    end

    test "returns the next unpredicted departure", %{stops: stops} do
      d1 = %Departure{
        prediction: %Prediction{},
        schedule: %Schedule{departure_time: ~U[2020-01-01T00:00:00Z]}
      }

      d2 = %Departure{
        prediction: nil,
        schedule: %Schedule{departure_time: ~U[2020-01-01T00:10:00Z]}
      }

      assert %{timestamp: "7:10"} = LineMap.serialize_scheduled_departure([d1, d2], stops)
    end

    test "returns the correct origin", %{stops: stops} do
      d = %Departure{
        prediction: nil,
        schedule: %Schedule{departure_time: ~U[2020-01-01T00:00:00Z]}
      }

      assert %{station_name: "Cleveland Circle"} =
               LineMap.serialize_scheduled_departure([d], stops)
    end
  end

  describe "slot_names/1" do
    test "returns left_sidebar" do
      instance = %LineMap{}
      assert [:left_sidebar] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns line_map" do
      instance = %LineMap{}
      assert :line_map == WidgetInstance.widget_type(instance)
    end
  end

  describe "audio_serialize/1" do
    test "returns empty string" do
      instance = %LineMap{}
      assert %{} == WidgetInstance.audio_serialize(instance)
    end
  end

  describe "audio_sort_key/1" do
    test "returns 0" do
      instance = %LineMap{}
      assert 0 == WidgetInstance.audio_sort_key(instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false" do
      instance = %LineMap{}
      refute WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns LineMapView" do
      instance = %LineMap{}
      assert ScreensWeb.Views.V2.Audio.LineMapView == WidgetInstance.audio_view(instance)
    end
  end
end
