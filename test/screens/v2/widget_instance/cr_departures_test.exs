defmodule Screens.V2.WidgetInstance.CRDeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Schedules.Schedule
  alias Screens.Predictions.Prediction
  alias Screens.Trips.Trip
  alias Screens.V2.{Departure, WidgetInstance}
  alias Screens.V2.WidgetInstance.CRDepartures, as: CRDeparturesWidget

  describe "priority/1" do
    test "returns 2" do
      instance = %CRDeparturesWidget{config: %{priority: [1]}}
      assert [1] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize_headsign/1" do
    test "handles default" do
      departure = %Departure{prediction: %Prediction{trip: %Trip{headsign: "Ruggles"}}}

      assert %{headsign: "Ruggles", station_service_list: []} ==
               CRDeparturesWidget.serialize_headsign(departure, "Nowhere")
    end

    test "handles via variations" do
      departure = %Departure{
        prediction: %Prediction{trip: %Trip{headsign: "South Station via Back Bay"}}
      }

      assert %{
               headsign: "South Station",
               station_service_list: [
                 %{name: "Ruggles", service: true},
                 %{name: "Back Bay", service: true}
               ]
             } ==
               CRDeparturesWidget.serialize_headsign(departure, "Back Bay")
    end

    test "handles parenthesized variations" do
      departure = %Departure{
        prediction: %Prediction{trip: %Trip{headsign: "Beth Israel (Limited Stops)"}}
      }

      assert %{headsign: "Beth Israel", station_service_list: []} ==
               CRDeparturesWidget.serialize_headsign(departure, "Somewhere")
    end
  end

  describe "serialize_departure/5" do
    test "serializes a departure with a schedule and a prediction" do
      now = ~U[2024-08-28 18:08:30.883227Z]

      departure = %Departure{
        schedule: %Schedule{
          id: "schedule-1",
          trip: %Trip{id: "trip-1", headsign: "Somewhere"},
          arrival_time: DateTime.add(now, 5, :minute),
          departure_time: DateTime.add(now, 7, :minute)
        },
        prediction: %Prediction{
          id: "prediction-1",
          trip: %Trip{id: "trip-1", headsign: "Somewhere"},
          arrival_time: DateTime.add(now, 5, :minute),
          departure_time: DateTime.add(now, 7, :minute)
        }
      }

      assert %{
               prediction_or_schedule_id: "prediction-1"
             } =
               CRDeparturesWidget.serialize_departure(
                 departure,
                 "Somewhere",
                 %{},
                 "place-smwhr",
                 now
               )
    end

    test "serializes a departure with only a schedule" do
      now = ~U[2024-08-28 18:08:30.883227Z]

      departure = %Departure{
        schedule: %Schedule{
          id: "schedule-1",
          trip: %Trip{id: "trip-1", headsign: "Somewhere"},
          arrival_time: DateTime.add(now, 5, :minute),
          departure_time: DateTime.add(now, 7, :minute)
        }
      }

      assert %{
               prediction_or_schedule_id: "schedule-1"
             } =
               CRDeparturesWidget.serialize_departure(
                 departure,
                 "Somewhere",
                 %{},
                 "place-smwhr",
                 now
               )
    end

    test "serializes a departure with only a prediction" do
      now = ~U[2024-08-28 18:08:30.883227Z]

      departure = %Departure{
        prediction: %Prediction{
          id: "prediction-1",
          trip: %Trip{id: "trip-1", headsign: "Somewhere"},
          arrival_time: DateTime.add(now, 5, :minute),
          departure_time: DateTime.add(now, 7, :minute)
        }
      }

      assert %{
               prediction_or_schedule_id: "prediction-1"
             } =
               CRDeparturesWidget.serialize_departure(
                 departure,
                 "Somewhere",
                 %{},
                 "place-smwhr",
                 now
               )
    end
  end
end
