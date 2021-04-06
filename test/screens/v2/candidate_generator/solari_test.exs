defmodule Screens.V2.CandidateGenerator.SolariTest do
  use ExUnit.Case, async: true

  alias Screens.Config
  alias Screens.V2.CandidateGenerator.Solari
  alias Screens.V2.WidgetInstance.NormalHeader

  setup do
    config = %Config.Screen{
      app_params: %Config.Solari{station_name: "Ruggles"},
      vendor: :solari,
      device_id: "TEST",
      name: "TEST",
      app_id: :solari
    }

    %{config: config}
  end

  describe "screen_template/0" do
    test "returns correct template" do
      assert {:screen,
              %{
                normal: [:header_normal, :main_content_normal],
                overhead: [:header_overhead, :main_content_overhead],
                takeover: [:full_screen]
              }} == Solari.screen_template()
    end
  end

  describe "candidate_instances/2" do
    test "returns expected header", %{config: config} do
      now = ~U[2020-04-06T10:00:00Z]
      assert [%NormalHeader{} = header_widget | _] = Solari.candidate_instances(config, now)

      assert %NormalHeader{
               screen: config,
               icon: nil,
               text: "Ruggles",
               time: ~U[2020-04-06T10:00:00Z]
             } == header_widget
    end
  end
end
