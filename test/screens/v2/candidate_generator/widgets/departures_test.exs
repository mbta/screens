defmodule Screens.V2.CandidateGenerator.Widgets.DeparturesTest do
  use ExUnit.Case, async: true

  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Departures.Filters.RouteDirections
  alias ScreensConfig.V2.Departures.Filters.RouteDirections.RouteDirection
  alias ScreensConfig.V2.Departures.{Filters, Section}
  alias ScreensConfig.V2.BusShelter
  alias ScreensConfig.V2.Departures, as: DeparturesConfig
  alias Screens.V2.CandidateGenerator.Widgets.Departures
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, OvernightDepartures}
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Trips.Trip

  describe "departures_instances/1" do
    setup do
      config = %Screen{
        app_params: %BusShelter{
          departures: %DeparturesConfig{
            sections: [%Section{query: "query A"}, %Section{query: "query B"}]
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
            %{type: :normal_section, rows: ["departure A1", "departure A2"]},
            %{type: :normal_section, rows: ["departure B1", "departure B2"]}
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
            %{type: :normal_section, rows: []},
            %{type: :normal_section, rows: []}
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

      expected_departures_instances = [
        %DeparturesNoData{screen: config, show_alternatives?: true}
      ]

      actual_departures_instances =
        Departures.departures_instances(config, fetch_section_departures_fn)

      assert expected_departures_instances == actual_departures_instances
    end

    test "returns OvernightDepartures if sections_data contains overnight atom", %{config: config} do
      fetch_section_departures_fn = fn
        %Section{query: "query A"} -> {:ok, []}
        %Section{query: "query B"} -> {:ok, []}
      end

      post_processing_fn = fn _sections, _config ->
        [:overnight]
      end

      expected_departures_instances = [
        %OvernightDepartures{}
      ]

      actual_departures_instances =
        Departures.departures_instances(config, fetch_section_departures_fn, post_processing_fn)

      assert expected_departures_instances == actual_departures_instances
    end

    test "returns DeparturesWidget with results from post processing", %{config: config} do
      fetch_section_departures_fn = fn
        %Section{query: "query A"} -> {:ok, []}
        %Section{query: "query B"} -> {:ok, ["departure B1"]}
      end

      post_processing_fn = fn sections, _config ->
        Enum.map(sections, fn {:ok, departures} ->
          {:ok, departures ++ ["notice"]}
        end)
      end

      expected_departures_instances = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{type: :normal_section, rows: ["notice"]},
            %{type: :normal_section, rows: ["departure B1", "notice"]}
          ]
        }
      ]

      actual_departures_instances =
        Departures.departures_instances(config, fetch_section_departures_fn, post_processing_fn)

      assert expected_departures_instances == actual_departures_instances
    end
  end

  describe "filter_departures/2" do
    test "filters departures with included route-directions" do
      departures = [r_d_departure("41", 1), r_d_departure("41", 0), r_d_departure("1", 1)]

      filters = %Filters{
        route_directions: %RouteDirections{
          action: :include,
          targets: [
            %RouteDirection{route_id: "39", direction_id: 0},
            %RouteDirection{route_id: "41", direction_id: 0}
          ]
        }
      }

      expected_filtered = [r_d_departure("41", 0)]

      assert {:ok, expected_filtered} == Departures.filter_departures({:ok, departures}, filters)
    end

    test "rejects departures with excluded route-directions" do
      departures = [r_d_departure("41", 1), r_d_departure("41", 0), r_d_departure("1", 1)]

      filters = %Filters{
        route_directions: %RouteDirections{
          action: :exclude,
          targets: [
            %RouteDirection{route_id: "39", direction_id: 0},
            %RouteDirection{route_id: "41", direction_id: 0}
          ]
        }
      }

      expected_filtered = [r_d_departure("41", 1), r_d_departure("1", 1)]

      assert {:ok, expected_filtered} == Departures.filter_departures({:ok, departures}, filters)
    end

    test "passes through :error" do
      assert :error == Departures.filter_departures(:error, %Filters{})
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
