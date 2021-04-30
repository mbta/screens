defmodule Screens.V2.CandidateGenerator.SolariLargeTest do
  use ExUnit.Case, async: true

  alias Screens.Config.{Screen, V2}
  alias Screens.V2.CandidateGenerator.SolariLarge
  alias Screens.V2.WidgetInstance.NormalHeader

  setup do
    config = %Screen{
      app_params: %V2.SolariLarge{
        departures: %V2.Departures{sections: []},
        header: %V2.Header{type: :current_stop_name, stop_name: "Ruggles"}
      },
      vendor: :gds,
      device_id: "TEST",
      name: "TEST",
      app_id: :solari_large_v2
    }

    %{config: config}
  end

  describe "screen_template/0" do
    test "returns correct template" do
      assert {:screen,
              %{
                normal: [:header, :main_content],
                takeover: [:full_screen]
              }} == SolariLarge.screen_template()
    end
  end

  describe "candidate_instances/2" do
    test "returns expected header", %{config: config} do
      now = ~U[2020-04-06T10:00:00Z]

      expected_header = %NormalHeader{
        screen: config,
        icon: nil,
        text: "Ruggles",
        time: ~U[2020-04-06T10:00:00Z]
      }

      assert expected_header in SolariLarge.candidate_instances(config, now)
    end
  end
end
