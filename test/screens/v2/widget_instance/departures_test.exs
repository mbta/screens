defmodule Screens.V2.WidgetInstance.DeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Trips.Trip
  alias Screens.V2.WidgetInstance

  setup_all do
    trip_headsign = "Ruggles"
    trip = %Trip{headsign: trip_headsign}

    route_name = "28"
    route = %Route{short_name: route_name}

    departure_time = ~U[2021-02-18 22:36:00Z]

    prediction = %Prediction{route: route, trip: trip, departure_time: departure_time}
    instance = %WidgetInstance.Departures{predictions: [prediction]}

    %{
      instance: instance,
      trip_headsign: trip_headsign,
      route_name: route_name,
      departure_time: departure_time
    }
  end

  describe "priority/1" do
    test "returns 2", %{instance: instance} do
      assert [2] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns serialized predictions", %{
      instance: instance,
      trip_headsign: trip_headsign,
      route_name: route_name,
      departure_time: departure_time
    } do
      assert %{
               departures: [
                 %{destination: trip_headsign, route: route_name, time: departure_time}
               ]
             } == WidgetInstance.serialize(instance)
    end
  end

  describe "slot_names/1" do
    test "returns main_content", %{instance: instance} do
      assert [:main_content] == WidgetInstance.slot_names(instance)
    end
  end
end
