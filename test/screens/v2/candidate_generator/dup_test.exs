defmodule Screens.V2.CandidateGenerator.DupTest do
  use ExUnit.Case, async: true

  alias Screens.Config
  alias Screens.V2.CandidateGenerator.Dup
  alias Screens.V2.WidgetInstance.NormalHeader

  setup do
    config = %Config.Screen{
      app_params: %Config.Dup{primary: %Config.Dup.Departures{header: "Tufts Medical Ctr"}},
      vendor: :outfront,
      device_id: "TEST",
      name: "TEST",
      app_id: :dup
    }

    %{config: config}
  end

  describe "screen_template/0" do
    test "returns correct template" do
      assert {:screen,
              %{
                normal: [:header, :main_content],
                full_takeover: [:full_screen]
              }} == Dup.screen_template()
    end
  end

  describe "candidate_instances/2" do
    test "returns expected header", %{config: config} do
      now = ~U[2020-04-06T10:00:00Z]

      expected_header = %NormalHeader{
        screen: config,
        icon: :logo,
        text: "Tufts Medical Ctr",
        time: ~U[2020-04-06T10:00:00Z]
      }

      assert expected_header in Dup.candidate_instances(config, now)
    end
  end
end
