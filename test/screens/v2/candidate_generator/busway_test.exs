defmodule Screens.V2.CandidateGenerator.BuswayTest do
  use ExUnit.Case, async: true

  alias ScreensConfig.{Screen, V2}
  alias Screens.V2.CandidateGenerator.Busway
  alias Screens.V2.WidgetInstance.{DeparturesNoData, NormalHeader}

  setup do
    config = %Screen{
      app_params: %V2.Busway{
        departures: %V2.Departures{sections: []},
        header: %V2.Header.CurrentStopName{stop_name: ""}
      },
      vendor: :solari,
      device_id: "TEST",
      name: "TEST",
      app_id: :solari_test_v2
    }

    deps = %Busway.Deps{departures_instances: fn _ -> [] end}

    %{config: config, deps: deps}
  end

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
    test "includes header with stop name", %{config: config, deps: deps} do
      now = ~U[2020-04-06T10:00:00Z]
      config = put_in(config.app_params.header.stop_name, "Ruggles")
      deps = struct!(deps, now: fn -> now end)

      expected_header = %NormalHeader{screen: config, icon: :logo, text: "Ruggles", time: now}
      assert expected_header in Busway.candidate_instances(config, [], deps)
    end

    test "includes departures instances", %{config: config, deps: deps} do
      no_data = %DeparturesNoData{screen: config, show_alternatives?: true}
      deps = struct!(deps, departures_instances: fn ^config -> [no_data] end)

      assert no_data in Busway.candidate_instances(config, [], deps)
    end
  end
end
