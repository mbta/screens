defmodule Screens.V2.CandidateGenerator.Widgets.DeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Config.Screen
  alias Screens.Config.V2.Departures.Filter.RouteDirection
  alias Screens.Config.V2.Departures.{Filter, Section}
  alias Screens.Config.V2.BusShelter
  alias Screens.Config.V2.Departures, as: DeparturesConfig
  alias Screens.V2.CandidateGenerator.Widgets.Departures
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.DeparturesNoData
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Trips.Trip

  describe "departures_instances/1" do
    setup do
      config = %Screen{
        app_params: %BusShelter{
          departures: %DeparturesConfig{
            sections: [
              %Section{query: "query A", filter: nil},
              %Section{query: "query B", filter: nil}
            ]
          },
          header: nil,
          footer: nil,
          alerts: nil
        },
        vendor: nil,
        device_id: nil,
        name: nil,
        app_id: nil
      }

      %{config: config}
    end

    test "returns DeparturesWidget when all section requests succeed and receive departure data",
         %{config: config} do
      fetch_section_departures_fn = fn
        %Section{query: "query A"} -> {:ok, ["departure A1", "departure A2"]}
        %Section{query: "query B"} -> {:ok, ["departure B1", "departure B2"]}
      end

      expected_departures_instances = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{type: :normal_section, departures: ["departure A1", "departure A2"]},
            %{type: :normal_section, departures: ["departure B1", "departure B2"]}
          ]
        }
      ]

      actual_departures_instances =
        Departures.departures_instances(config, fetch_section_departures_fn)

      assert expected_departures_instances == actual_departures_instances
    end

    test "returns DeparturesWidget when all sections requests succeed but receive no departure data",
         %{config: config} do
      fetch_section_departures_fn = fn
        %Section{query: "query A"} -> {:ok, []}
        %Section{query: "query B"} -> {:ok, []}
      end

      expected_departures_instances = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{type: :normal_section, departures: []},
            %{type: :normal_section, departures: []}
          ]
        }
      ]

      actual_departures_instances =
        Departures.departures_instances(config, fetch_section_departures_fn)

      assert expected_departures_instances == actual_departures_instances
    end

    test "returns DeparturesNoData if any section request fails", %{config: config} do
      fetch_section_departures_fn = fn
        %Section{query: "query A"} -> {:ok, []}
        %Section{query: "query B"} -> :error
      end

      expected_departures_instances = [%DeparturesNoData{screen: config}]

      actual_departures_instances =
        Departures.departures_instances(config, fetch_section_departures_fn)

      assert expected_departures_instances == actual_departures_instances
    end
  end

  describe "filter_departures/2" do
    test "filters departures with included route-directions" do
      departures = [r_d_departure("41", 1), r_d_departure("41", 0), r_d_departure("1", 1)]

      filter = %Filter{
        action: :include,
        route_directions: [
          %RouteDirection{route_id: "39", direction_id: 0},
          %RouteDirection{route_id: "41", direction_id: 0}
        ]
      }

      expected_filtered = [r_d_departure("41", 0)]

      assert {:ok, expected_filtered} == Departures.filter_departures({:ok, departures}, filter)
    end

    test "rejects departures with excluded route-directions" do
      departures = [r_d_departure("41", 1), r_d_departure("41", 0), r_d_departure("1", 1)]

      filter = %Filter{
        action: :exclude,
        route_directions: [
          %RouteDirection{route_id: "39", direction_id: 0},
          %RouteDirection{route_id: "41", direction_id: 0}
        ]
      }

      expected_filtered = [r_d_departure("41", 1), r_d_departure("1", 1)]

      assert {:ok, expected_filtered} == Departures.filter_departures({:ok, departures}, filter)
    end

    test "passes through :error" do
      assert :error == Departures.filter_departures(:error, nil)
    end
  end

  defp r_d_departure(route_id, direction_id) do
    %Departure{
      prediction: %Prediction{
        route: %Route{id: route_id},
        trip: %Trip{direction_id: direction_id}
      }
    }
  end
end
