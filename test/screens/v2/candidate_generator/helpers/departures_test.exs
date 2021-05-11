defmodule Screens.V2.CandidateGenerator.Helpers.DeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Config.Screen
  alias Screens.Config.V2.Departures.Section
  alias Screens.Config.V2.BusShelter
  alias Screens.Config.V2.Departures, as: DeparturesConfig
  alias Screens.V2.CandidateGenerator.Helpers.Departures
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.DeparturesNoData

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
        footer: nil
      },
      vendor: nil,
      device_id: nil,
      name: nil,
      app_id: nil
    }

    %{config: config}
  end

  describe "departures_instances/1" do
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
end
