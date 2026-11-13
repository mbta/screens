defmodule Screens.V2.WidgetInstance.LineMapTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Predictions.Prediction
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V2.{Departure, WidgetInstance}
  alias Screens.V2.WidgetInstance.LineMap
  alias Screens.Vehicles.Vehicle

  import Screens.TestSupport.InformedEntityBuilder

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

    reverse_stops = [
      %Stop{id: "70206", name: "North Station"},
      %Stop{id: "70204", name: "Haymarket"},
      %Stop{id: "70202", name: "Government Center"},
      %Stop{id: "70199", name: "Park Street"},
      %Stop{id: "70231", name: "Washington Square"},
      %Stop{id: "70233", name: "Tappan Street"},
      %Stop{id: "70235", name: "Dean Road"},
      %Stop{id: "70237", name: "Englewood Avenue"},
      %Stop{id: "70239", name: "Cleveland Circle"}
    ]

    %{stops: stops, reverse_stops: reverse_stops}
  end

  defp call_serialize_stops(current_stop, stops, reverse_stops, alerts \\ []) do
    LineMap.serialize_stops(current_stop, stops, reverse_stops, false, "Green-C", alerts)
  end

  defp stop_summary(stops) do
    Enum.map(stops, &{&1.label, &1.current, &1.downstream, &1.terminal})
  end

  describe "priority/1" do
    test "returns 2" do
      instance = %LineMap{}
      assert [2] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize_stops/2" do
    test "returns past stops and up two future stops in order", %{
      stops: stops,
      reverse_stops: reverse_stops
    } do
      assert [
               {"Government Center", false, true, false},
               {"Park Street", false, true, false},
               {"Washington Square", true, false, false},
               {"Tappan Street", false, false, false},
               {"Dean Road", false, false, false},
               {"Englewood Avenue", false, false, false},
               {"Cleveland Circle", false, false, true}
             ] ==
               call_serialize_stops("70230", stops, reverse_stops)
               |> stop_summary()
    end

    test "handles fewer than two future stops", %{stops: stops, reverse_stops: reverse_stops} do
      assert [
               {"North Station", false, true, true},
               {"Haymarket", true, false, false},
               {"Government Center", false, false, false},
               {"Park Street", false, false, false},
               {"Washington Square", false, false, false},
               {"Tappan Street", false, false, false},
               {"Dean Road", false, false, false},
               {"Englewood Avenue", false, false, false},
               {"Cleveland Circle", false, false, true}
             ] ==
               call_serialize_stops("70203", stops, reverse_stops)
               |> stop_summary()
    end

    test "marks closed stops based on alerts", %{stops: stops, reverse_stops: reverse_stops} do
      alert = %Alert{
        effect: :station_closure,
        informed_entities: [
          ie(stop_id: "70236", route_id: "Green-C", activities: [:boarding, :exit]),
          ie(stop_id: "70234", route_id: "Green-C", activities: [:boarding, :exit])
        ]
      }

      result = call_serialize_stops("70230", stops, reverse_stops, [alert])

      # Find the stops in the result
      assert Enum.find(result, &(&1.label == "Englewood Avenue")).closed == true
      assert Enum.find(result, &(&1.label == "Dean Road")).closed == true
      assert Enum.find(result, &(&1.label == "Tappan Street")).closed == false
    end

    test "handles multiple closure alert types", %{stops: stops, reverse_stops: reverse_stops} do
      alerts = [
        %Alert{
          effect: :stop_closure,
          informed_entities: [
            ie(stop_id: "70236", route_id: "Green-C", activities: [:boarding, :exit])
          ]
        },
        %Alert{
          effect: :suspension,
          informed_entities: [
            ie(stop_id: "70234", route_id: "Green-C", activities: [:boarding, :exit])
          ]
        },
        %Alert{
          effect: :shuttle,
          informed_entities: [
            ie(stop_id: "70232", route_id: "Green-C", activities: [:boarding, :exit])
          ]
        }
      ]

      result = call_serialize_stops("70230", stops, reverse_stops, alerts)

      assert Enum.find(result, &(&1.label == "Englewood Avenue")).closed == true
      assert Enum.find(result, &(&1.label == "Dean Road")).closed == true
      assert Enum.find(result, &(&1.label == "Tappan Street")).closed == true
    end

    test "does not show downstream stations where you can exit as closed", %{
      stops: stops,
      reverse_stops: reverse_stops
    } do
      alerts = [
        %Alert{
          effect: :stop_closure,
          informed_entities: [
            ie(stop_id: "70236", route_id: "Green-C", activities: [:boarding])
          ]
        },
        %Alert{
          effect: :suspension,
          informed_entities: [
            ie(stop_id: "70234", route_id: "Green-C", activities: [:boarding, :exit])
          ]
        }
      ]

      result = call_serialize_stops("70230", stops, reverse_stops, alerts)

      assert Enum.find(result, &(&1.label == "Englewood Avenue")).closed == false
      assert Enum.find(result, &(&1.label == "Dean Road")).closed == true
    end
  end

  describe "serialize_vehicles/5" do
    test "filters irrelevant departures", %{stops: stops, reverse_stops: reverse_stops} do
      d1 = %Departure{prediction: nil}
      d2 = %Departure{prediction: %Prediction{vehicle: nil}}
      d3 = %Departure{prediction: %Prediction{vehicle: %Vehicle{direction_id: 1}}}
      departures = [d1, d2, d3]

      direction_id = 0
      current_stop = "70230"
      now = ~U[2020-01-01T02:00:00Z]

      assert [] ==
               LineMap.serialize_vehicles(
                 departures,
                 stops,
                 reverse_stops,
                 direction_id,
                 current_stop,
                 now,
                 false
               )
    end

    test "correctly computes indexes of relevant departures", %{
      stops: stops,
      reverse_stops: reverse_stops
    } do
      direction_id = 0
      current_stop = "70230"
      now = ~U[2020-01-01T02:00:00Z]

      v = %Vehicle{id: "1", current_status: :stopped_at, stop_id: "70236", direction_id: 0}
      t = %Trip{id: "1", direction_id: 0}

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:02:00Z], vehicle: v, trip: t}
      }

      assert [%{index: 5.0}] =
               LineMap.serialize_vehicles(
                 [d],
                 stops,
                 reverse_stops,
                 direction_id,
                 current_stop,
                 now,
                 false
               )

      v = %Vehicle{v | stop_id: "70203"}

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:02:00Z], vehicle: v, trip: t}
      }

      assert [] ==
               LineMap.serialize_vehicles(
                 [d],
                 stops,
                 reverse_stops,
                 direction_id,
                 current_stop,
                 now,
                 false
               )

      v = %Vehicle{v | stop_id: "70238"}

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:02:00Z], vehicle: v, trip: t}
      }

      assert [%{index: 6.0}] =
               LineMap.serialize_vehicles(
                 [d],
                 stops,
                 reverse_stops,
                 direction_id,
                 current_stop,
                 now,
                 false
               )

      v = %Vehicle{v | current_status: :in_transit_to}

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:02:00Z], vehicle: v, trip: t}
      }

      assert [%{index: 6.0}] =
               LineMap.serialize_vehicles(
                 [d],
                 stops,
                 reverse_stops,
                 direction_id,
                 current_stop,
                 now,
                 false
               )

      v = %Vehicle{v | stop_id: "70230"}

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:02:00Z], vehicle: v, trip: t}
      }

      assert [%{index: 2.7}] =
               LineMap.serialize_vehicles(
                 [d],
                 stops,
                 reverse_stops,
                 direction_id,
                 current_stop,
                 now,
                 false
               )

      assert [] =
               LineMap.serialize_vehicles(
                 [d],
                 stops,
                 reverse_stops,
                 direction_id,
                 "bad_stop",
                 now,
                 false
               )
    end

    test "correctly serializes labels", %{stops: stops, reverse_stops: reverse_stops} do
      direction_id = 0
      current_stop = "70230"
      now = ~U[2020-01-01T02:00:00Z]

      v = %Vehicle{id: "1", current_status: :stopped_at, stop_id: "70236", direction_id: 0}
      t = %Trip{id: "1", direction_id: 0}

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:02:00Z], vehicle: v, trip: t}
      }

      assert [%{id: "1", label: %{type: :minutes, minutes: 2}}] =
               LineMap.serialize_vehicles(
                 [d],
                 stops,
                 reverse_stops,
                 direction_id,
                 current_stop,
                 now,
                 false
               )

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:00:30Z], vehicle: v, trip: t}
      }

      assert [%{id: "1", label: %{type: :text, text: "Now"}}] =
               LineMap.serialize_vehicles(
                 [d],
                 stops,
                 reverse_stops,
                 direction_id,
                 current_stop,
                 now,
                 false
               )
    end

    test "doesn't label departed vehicles", %{stops: stops, reverse_stops: reverse_stops} do
      direction_id = 0
      current_stop = "70230"
      now = ~U[2020-01-01T02:00:00Z]

      v = %Vehicle{
        id: "1",
        current_status: :stopped_at,
        stop_id: "70200",
        direction_id: direction_id
      }

      t = %Trip{id: "1", direction_id: direction_id}

      d = %Departure{
        prediction: %Prediction{departure_time: ~U[2020-01-01T02:02:00Z], vehicle: v, trip: t}
      }

      assert [%{id: "1", label: nil}] =
               LineMap.serialize_vehicles(
                 [d],
                 stops,
                 reverse_stops,
                 direction_id,
                 current_stop,
                 now,
                 false
               )
    end

    test "returns empty array when vehicle stop index or current stop index is not found", %{
      stops: stops,
      reverse_stops: reverse_stops
    } do
      direction_id = 0
      now = ~U[2020-01-01T02:00:00Z]

      current_stop = "70230"
      bad_current_stop_id = "3"

      good_departure = %Departure{
        prediction: %Prediction{
          departure_time: ~U[2020-01-01T02:02:00Z],
          vehicle: %Vehicle{
            id: "1",
            current_status: :stopped_at,
            stop_id: "70236",
            direction_id: 0
          },
          trip: %Trip{id: "1", direction_id: 0}
        }
      }

      bad_departure = %Departure{
        prediction: %Prediction{
          departure_time: ~U[2020-01-01T02:02:00Z],
          vehicle: %Vehicle{
            id: "1",
            current_status: :stopped_at,
            stop_id: "3",
            direction_id: 0
          },
          trip: %Trip{id: "1", direction_id: 0}
        }
      }

      assert [] =
               LineMap.serialize_vehicles(
                 [bad_departure],
                 stops,
                 reverse_stops,
                 direction_id,
                 current_stop,
                 now,
                 false
               )

      assert [] =
               LineMap.serialize_vehicles(
                 [good_departure],
                 stops,
                 reverse_stops,
                 direction_id,
                 bad_current_stop_id,
                 now,
                 false
               )
    end
  end

  describe "serialize_scheduled_departure/2" do
    test "returns nil when there are two or more predictions", %{stops: stops} do
      direction_id = 1

      d1 = %Departure{prediction: %Prediction{trip: %Trip{direction_id: direction_id}}}
      d2 = %Departure{prediction: %Prediction{trip: %Trip{direction_id: direction_id}}}

      d3 = %Departure{
        prediction: nil,
        schedule: %Schedule{
          departure_time: ~U[2020-01-01T02:20:00Z],
          trip: %Trip{direction_id: direction_id}
        }
      }

      assert nil ==
               LineMap.serialize_scheduled_departure([d1, d2, d3], direction_id, stops, false)

      assert not is_nil(
               LineMap.serialize_scheduled_departure([d1, d3], direction_id, stops, false)
             )
    end

    test "returns the next unpredicted departure", %{stops: stops} do
      direction_id = 1

      d1 = %Departure{
        prediction: %Prediction{},
        schedule: %Schedule{departure_time: ~U[2020-01-01T00:00:00Z]}
      }

      d2 = %Departure{
        prediction: nil,
        schedule: %Schedule{departure_time: ~U[2020-01-01T00:10:00Z]}
      }

      assert %{timestamp: "7:10"} =
               LineMap.serialize_scheduled_departure([d1, d2], direction_id, stops, false)
    end

    test "returns nil when there are no departures", %{stops: stops} do
      direction_id = 1
      assert nil == LineMap.serialize_scheduled_departure([], direction_id, stops, false)
    end

    test "returns nil when there are only predictions", %{stops: stops} do
      direction_id = 1
      d1 = %Departure{prediction: %Prediction{trip: %Trip{direction_id: direction_id}}}
      assert nil == LineMap.serialize_scheduled_departure([d1], direction_id, stops, false)
    end

    test "returns the correct origin", %{stops: stops} do
      direction_id = 1

      d = %Departure{
        prediction: nil,
        schedule: %Schedule{departure_time: ~U[2020-01-01T00:00:00Z]}
      }

      assert %{station_name: "Cleveland Circle"} =
               LineMap.serialize_scheduled_departure([d], direction_id, stops, false)
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
    test "returns [0]" do
      instance = %LineMap{}
      assert [0] == WidgetInstance.audio_sort_key(instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false" do
      instance = %LineMap{}
      refute WidgetInstance.audio_valid_candidate?(instance)
    end
  end
end
