defmodule Screens.V2.CandidateGenerator.DupNew.DeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.DupNew
  alias Screens.V2.RDS
  alias Screens.V2.WidgetInstance.DeparturesNoData
  alias ScreensConfig.{Alerts, Departures, Header}
  alias ScreensConfig.Departures.{Query, Section}
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.Dup, as: DupConfig

  import Mox
  import Screens.Inject

  setup :verify_on_exit!

  @rds injected(RDS)

  @now ~U[2020-04-06T10:00:00Z]
  @config %Screen{
    app_params: %DupConfig{
      header: %Header.StopId{stop_id: "place-test"},
      primary_departures: %Departures{
        sections: []
      },
      secondary_departures: %Departures{
        sections: []
      },
      alerts: struct(Alerts)
    },
    vendor: :outfront,
    device_id: "TEST",
    name: "TEST",
    app_id: :dup_v2
  }

  defp put_primary_departures(config, primary_departures_sections) do
    %{
      config
      | app_params: %{
          config.app_params
          | primary_departures: %Departures{sections: primary_departures_sections}
        }
    }
  end

  defp put_secondary_departures_sections(config, secondary_departures_sections) do
    %{
      config
      | app_params: %{
          config.app_params
          | secondary_departures: %Departures{sections: secondary_departures_sections}
        }
    }
  end

  setup do
    stub(@rds, :get, fn _, _ -> [{:ok, []}] end)
    :ok
  end

  describe "instances/3" do
    test "returns DeparturesNoData on RDS returning errors" do
      primary_departures = [
        %Section{query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}},
        %Section{query: %Query{params: %Query.Params{stop_ids: ["place-B"]}}}
      ]

      secondary_departures = [
        %Section{query: %Query{params: %Query.Params{stop_ids: ["place-C"]}}},
        %Section{query: %Query{params: %Query.Params{stop_ids: ["place-D"]}}}
      ]

      config =
        @config
        |> put_primary_departures(primary_departures)
        |> put_secondary_departures_sections(secondary_departures)

      expect(@rds, :get, fn _primary_departures, @now -> [:error, :error] end)
      expect(@rds, :get, fn _secondary_departures, @now -> [:error, :error] end)

      expected_instances = [
        %DeparturesNoData{screen: config, slot_name: :main_content_zero},
        %DeparturesNoData{screen: config, slot_name: :main_content_one},
        %DeparturesNoData{screen: config, slot_name: :main_content_reduced_zero},
        %DeparturesNoData{screen: config, slot_name: :main_content_reduced_one},
        %DeparturesNoData{screen: config, slot_name: :main_content_two},
        %DeparturesNoData{screen: config, slot_name: :main_content_reduced_two}
      ]

      actual_instances = DupNew.Departures.instances(config, @now)

      assert actual_instances == expected_instances
    end
  end
end
