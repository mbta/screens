defmodule Screens.V2.CandidateGenerator.BuswayTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.Busway
  alias Screens.V2.WidgetInstance.DeparturesNoData
  alias ScreensConfig, as: Config
  alias ScreensConfig.Screen

  @config %Screen{
    app_params: %Screen.Busway{
      departures: %Config.Departures{sections: []},
      header: %Config.Header.StopName{stop_name: ""}
    },
    vendor: :solari,
    device_id: "TEST",
    name: "TEST",
    app_id: :solari_test_v2
  }

  describe "screen_template/1" do
    test "returns correct template" do
      assert {:screen,
              %{
                normal: [:header, :main_content],
                takeover: [:full_screen]
              }} == Busway.screen_template(@config)
    end
  end

  describe "candidate_instances/2" do
    test "includes departures instances" do
      now = ~U[2020-04-06T10:00:00Z]
      no_data = %DeparturesNoData{screen: @config, show_alternatives?: true}
      instance_fns = [fn @config, ^now -> [no_data] end]

      assert no_data in Busway.candidate_instances(@config, now, instance_fns)
    end
  end
end
