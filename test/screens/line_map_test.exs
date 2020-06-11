defmodule Screens.LineMapTest do
  use ExUnit.Case, async: true

  alias Screens.Stops.Stop
  alias Screens.Vehicles.Vehicle
  alias Screens.Predictions.Prediction
  alias Screens.LineMap

  @route_stops [
    %Stop{id: "70196", name: "Park Street"},
    %Stop{id: "70155", name: "Copley"},
    %Stop{id: "71151", name: "Kenmore"},
    %Stop{id: "70149", name: "Blandford Street"},
    %Stop{id: "70137", name: "Babcock Street"},
    %Stop{id: "70113", name: "Chestnut Hill Avenue"},
    %Stop{id: "70107", name: "Boston College"}
  ]

  @current_stop_index 3

  describe "filter_predictions_by_vehicles/4" do
    test "does not filter predictions from vehicles before or at current stop" do
      predictions = [%Prediction{trip: %{id: 1}}, %Prediction{trip: %{id: 2}}]
      vehicles = [%Vehicle{trip_id: 1, stop_id: "70196"}, %Vehicle{trip_id: 1, stop_id: "70149"}]

      result =
        LineMap.filter_predictions_by_vehicles(
          predictions,
          vehicles,
          @route_stops,
          @current_stop_index
        )

      assert [%Prediction{trip: %{id: 1}}, %Prediction{trip: %{id: 2}}] == result
    end

    test "filters predictions from vehicles after current stop" do
      predictions = [%Prediction{trip: %{id: 1}}]
      vehicles = [%Vehicle{trip_id: 1, stop_id: "70107"}]

      result =
        LineMap.filter_predictions_by_vehicles(
          predictions,
          vehicles,
          @route_stops,
          @current_stop_index
        )

      assert [] == result
    end

    test "does not filter predictions from vehicles not in route_stops" do
      predictions = [%Prediction{trip: %{id: 1}}]
      vehicles = [%Vehicle{trip_id: 1, stop_id: "70202"}]

      result =
        LineMap.filter_predictions_by_vehicles(
          predictions,
          vehicles,
          @route_stops,
          @current_stop_index
        )

      assert [%Prediction{trip: %{id: 1}}] == result
    end
  end
end
