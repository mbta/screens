defmodule Screens.V2.WidgetInstance.DeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Trips.Trip
  alias Screens.V2.WidgetInstance

  @trip %Trip{headsign: "Ruggles"}
  @route %Route{short_name: "28"}
  @time ~U[2021-02-18 22:36:00Z]
  @prediction %Prediction{route: @route, trip: @trip, departure_time: @time}
  @instance %WidgetInstance.Departures{predictions: [@prediction]}

  describe "priority/1" do
    test "returns 2" do
      assert [2] == WidgetInstance.priority(@instance)
    end
  end

  describe "serialize/1" do
    test "returns serialized predictions" do
      assert %{
               departures: [
                 %{destination: "Ruggles", route: "28", time: ~U[2021-02-18 22:36:00Z]}
               ]
             } == WidgetInstance.serialize(@instance)
    end
  end

  describe "slot_names/1" do
    test "returns main_content" do
      assert [:main_content] == WidgetInstance.slot_names(@instance)
    end
  end
end
