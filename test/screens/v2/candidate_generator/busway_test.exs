defmodule Screens.V2.CandidateGenerator.BuswayTest do
  use ExUnit.Case, async: true

  alias ScreensConfig.{Screen, V2}
  alias Screens.V2.CandidateGenerator.Busway
  alias Screens.V2.ScreenData.QueryParams
  alias Screens.V2.WidgetInstance.{DeparturesNoData, NormalHeader}

  @config %Screen{
    app_params: %V2.Busway{
      departures: %V2.Departures{sections: []},
      header: %V2.Header.CurrentStopName{stop_name: ""}
    },
    vendor: :solari,
    device_id: "TEST",
    name: "TEST",
    app_id: :solari_test_v2
  }

  describe "screen_template/0" do
    test "returns correct template" do
      assert {:screen,
              %{
                normal: [:header, :main_content],
                takeover: [:full_screen]
              }} == Busway.screen_template()
    end
  end

  describe "candidate_instances/2" do
    test "includes header with stop name" do
      now = ~U[2020-04-06T10:00:00Z]
      config = put_in(@config.app_params.header.stop_name, "Ruggles")

      expected_header = %NormalHeader{screen: config, icon: :logo, text: "Ruggles", time: now}

      assert expected_header in Busway.candidate_instances(
               config,
               %QueryParams{},
               now,
               _instance_fns = []
             )
    end

    test "includes departures instances" do
      now = ~U[2020-04-06T10:00:00Z]
      no_data = %DeparturesNoData{screen: @config, show_alternatives?: true}
      instance_fns = [fn @config, ^now -> [no_data] end]

      assert no_data in Busway.candidate_instances(@config, %QueryParams{}, now, instance_fns)
    end
  end
end
