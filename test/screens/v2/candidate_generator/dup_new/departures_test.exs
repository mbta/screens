defmodule Screens.V2.CandidateGenerator.DupNew.DeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Lines.Line
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V2.CandidateGenerator.DupNew
  alias Screens.V2.Departure
  alias Screens.V2.RDS
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, DeparturesNoService}
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

  defp rds_countdown(stop_id, line_id, headsign, expected_departures) do
    %RDS{
      stop: %Stop{id: stop_id},
      line: %Line{id: line_id},
      headsign: headsign,
      state: %RDS.Countdowns{
        departures: expected_departures
      }
    }
  end

  defp no_service(stop_id, line_id, headsign) do
    %RDS{
      stop: %Stop{id: stop_id},
      line: %Line{id: line_id},
      headsign: headsign,
      state: %RDS.NoService{}
    }
  end

  defp expected_departures_widget(config, expected_primary_sections, expected_secondary_sections) do
    [
      %DeparturesWidget{
        screen: config,
        slot_names: [:main_content_zero],
        now: @now,
        sections: expected_primary_sections
      },
      %DeparturesWidget{
        screen: config,
        slot_names: [:main_content_one],
        now: @now,
        sections: expected_primary_sections
      },
      %DeparturesWidget{
        screen: config,
        slot_names: [:main_content_reduced_zero],
        now: @now,
        sections: expected_primary_sections
      },
      %DeparturesWidget{
        screen: config,
        slot_names: [:main_content_reduced_one],
        now: @now,
        sections: expected_primary_sections
      },
      %DeparturesWidget{
        screen: config,
        slot_names: [:main_content_two],
        now: @now,
        sections: expected_secondary_sections
      },
      %DeparturesWidget{
        screen: config,
        slot_names: [:main_content_reduced_two],
        now: @now,
        sections: expected_secondary_sections
      }
    ]
  end

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

    test "returns DeparturesNoService on RDS returning no predictions or scheduled departures for Countdown state" do
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

      expect(@rds, :get, fn _primary_departures, @now -> [{:ok, []}, {:ok, []}] end)
      expect(@rds, :get, fn _secondary_departures, @now -> [{:ok, []}, {:ok, []}] end)

      expected_instances = [
        %DeparturesNoService{screen: config, slot_name: :main_content_zero},
        %DeparturesNoService{screen: config, slot_name: :main_content_one},
        %DeparturesNoService{screen: config, slot_name: :main_content_reduced_zero},
        %DeparturesNoService{screen: config, slot_name: :main_content_reduced_one},
        %DeparturesNoService{screen: config, slot_name: :main_content_two},
        %DeparturesNoService{screen: config, slot_name: :main_content_reduced_two}
      ]

      actual_instances = DupNew.Departures.instances(config, @now)

      assert actual_instances == expected_instances
    end

    test "secondary departures fallback to primary departures when empty" do
      primary_departures = [
        %Section{query: %Query{params: %Query.Params{stop_ids: ["s1"]}}},
        %Section{query: %Query{params: %Query.Params{stop_ids: ["s2"]}}}
      ]

      secondary_departures = []

      expected_departures = [
        %Departure{
          prediction: %Prediction{
            arrival_time: ~U[2024-10-11 12:27:00Z],
            departure_time: ~U[2024-10-11 12:30:00Z],
            route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
            stop: %Stop{id: "s1"},
            trip: %Trip{headsign: "other1", pattern_headsign: "h1"}
          },
          schedule: nil
        }
      ]

      expected_primary_sections = [
        %Screens.V2.WidgetInstance.Departures.NormalSection{
          header: %ScreensConfig.Departures.Header{
            arrow: nil,
            read_as: nil,
            subtitle: nil,
            title: nil
          },
          layout: %ScreensConfig.Departures.Layout{
            base: nil,
            include_later: false,
            max: nil,
            min: 1
          },
          grouping_type: :time,
          rows: expected_departures
        }
      ]

      config =
        @config
        |> put_primary_departures(primary_departures)
        |> put_secondary_departures_sections(secondary_departures)

      expect(@rds, :get, fn _primary_departures, @now ->
        [
          {:ok, [rds_countdown("s1", "l1", "other1", expected_departures)]}
        ]
      end)

      expect(@rds, :get, fn _secondary_departures, @now -> [{:ok, []}, {:ok, []}] end)

      expected_instances =
        expected_departures_widget(config, expected_primary_sections, expected_primary_sections)

      actual_instances = DupNew.Departures.instances(config, @now)

      assert actual_instances == expected_instances
    end

    test "creates no service sections for no service states" do
      primary_departures = [
        %Section{query: %Query{params: %Query.Params{stop_ids: ["s1"]}}},
        %Section{query: %Query{params: %Query.Params{stop_ids: ["s2"]}}}
      ]

      secondary_departures = []

      expected_departures = [
        %Departure{
          prediction: %Prediction{
            arrival_time: ~U[2024-10-11 12:27:00Z],
            departure_time: ~U[2024-10-11 12:30:00Z],
            route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
            stop: %Stop{id: "s1"},
            trip: %Trip{headsign: "other1", pattern_headsign: "h1"}
          },
          schedule: nil
        }
      ]

      expected_primary_sections = [
        %Screens.V2.WidgetInstance.Departures.NormalSection{
          header: %ScreensConfig.Departures.Header{
            arrow: nil,
            read_as: nil,
            subtitle: nil,
            title: nil
          },
          layout: %ScreensConfig.Departures.Layout{
            base: nil,
            include_later: false,
            max: nil,
            min: 1
          },
          grouping_type: :time,
          rows: expected_departures
        },
        %Screens.V2.WidgetInstance.Departures.NoServiceSection{route: nil}
      ]

      config =
        @config
        |> put_primary_departures(primary_departures)
        |> put_secondary_departures_sections(secondary_departures)

      expect(@rds, :get, fn _primary_departures, @now ->
        [
          {:ok,
           [
             rds_countdown("s1", "l1", "other1", expected_departures)
           ]},
          {:ok, [no_service("s2", "l2", "other2")]}
        ]
      end)

      expect(@rds, :get, fn _secondary_departures, @now -> [{:ok, []}, {:ok, []}] end)

      expected_instances =
        expected_departures_widget(config, expected_primary_sections, expected_primary_sections)

      actual_instances = DupNew.Departures.instances(config, @now)

      assert actual_instances == expected_instances
    end

    test "creates NormalSections for upcoming predictions and schedules" do
      primary_departures = [
        %Section{query: %Query{params: %Query.Params{stop_ids: ["s1"]}}},
        %Section{query: %Query{params: %Query.Params{stop_ids: ["s2"]}}}
      ]

      secondary_departures = [
        %Section{query: %Query{params: %Query.Params{stop_ids: ["s3"]}}},
        %Section{query: %Query{params: %Query.Params{stop_ids: ["s4"]}}}
      ]

      expected_primary_departures = [
        %Departure{
          prediction: %Prediction{
            arrival_time: ~U[2024-10-11 12:27:00Z],
            departure_time: ~U[2024-10-11 12:30:00Z],
            route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
            stop: %Stop{id: "s1"},
            trip: %Trip{headsign: "other1", pattern_headsign: "h1"}
          },
          schedule: nil
        }
      ]

      expected_secondary_departures = [
        %Departure{
          prediction: nil,
          schedule: %Schedule{
            departure_time: ~U[2024-10-11 13:15:00Z],
            route: %Route{id: "r3", line: %Line{id: "l3"}, type: :ferry},
            stop: %Stop{id: "s3"},
            trip: %Trip{headsign: "other3", pattern_headsign: "h3"}
          }
        }
      ]

      expected_primary_sections = [
        %Screens.V2.WidgetInstance.Departures.NormalSection{
          header: %ScreensConfig.Departures.Header{
            arrow: nil,
            read_as: nil,
            subtitle: nil,
            title: nil
          },
          layout: %ScreensConfig.Departures.Layout{
            base: nil,
            include_later: false,
            max: nil,
            min: 1
          },
          grouping_type: :time,
          rows: expected_primary_departures
        }
      ]

      expected_secondary_sections = [
        %Screens.V2.WidgetInstance.Departures.NormalSection{
          header: %ScreensConfig.Departures.Header{
            arrow: nil,
            read_as: nil,
            subtitle: nil,
            title: nil
          },
          layout: %ScreensConfig.Departures.Layout{
            base: nil,
            include_later: false,
            max: nil,
            min: 1
          },
          grouping_type: :time,
          rows: expected_secondary_departures
        }
      ]

      config =
        @config
        |> put_primary_departures(primary_departures)
        |> put_secondary_departures_sections(secondary_departures)

      expect(@rds, :get, fn _primary_departures, @now ->
        [{:ok, [rds_countdown("s1", "l1", "other1", expected_primary_departures)]}]
      end)

      expect(@rds, :get, fn _secondary_departures, @now ->
        [{:ok, [rds_countdown("s3", "l3", "other3", expected_secondary_departures)]}]
      end)

      expected_instances =
        expected_departures_widget(config, expected_primary_sections, expected_secondary_sections)

      actual_instances = DupNew.Departures.instances(config, @now)

      assert actual_instances == expected_instances
    end

    test "handles bidirectional flag while creating departure sections" do
      primary_departures = [
        %Section{bidirectional: true, query: %Query{params: %Query.Params{stop_ids: ["s1"]}}}
      ]

      expected_departures = [
        %Departure{
          prediction: %Prediction{
            arrival_time: ~U[2024-10-11 12:27:00Z],
            departure_time: ~U[2024-10-11 12:30:00Z],
            route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
            stop: %Stop{id: "s1"},
            trip: %Trip{headsign: "other1", pattern_headsign: "h1", direction_id: 0}
          },
          schedule: nil
        },
        %Departure{
          prediction: %Prediction{
            arrival_time: ~U[2024-10-11 12:30:00Z],
            departure_time: ~U[2024-10-11 12:32:00Z],
            route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
            stop: %Stop{id: "s1"},
            trip: %Trip{headsign: "other3", pattern_headsign: "h3", direction_id: 1}
          },
          schedule: nil
        }
      ]

      all_departures = [
        %Departure{
          prediction: %Prediction{
            arrival_time: ~U[2024-10-11 12:27:00Z],
            departure_time: ~U[2024-10-11 12:30:00Z],
            route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
            stop: %Stop{id: "s1"},
            trip: %Trip{headsign: "other1", pattern_headsign: "h1", direction_id: 0}
          },
          schedule: nil
        },
        %Departure{
          prediction: %Prediction{
            arrival_time: ~U[2024-10-11 12:27:00Z],
            departure_time: ~U[2024-10-11 12:30:00Z],
            route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
            stop: %Stop{id: "s1"},
            trip: %Trip{headsign: "other1", pattern_headsign: "h1", direction_id: 0}
          },
          schedule: nil
        },
        %Departure{
          prediction: %Prediction{
            arrival_time: ~U[2024-10-11 12:27:00Z],
            departure_time: ~U[2024-10-11 12:30:00Z],
            route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
            stop: %Stop{id: "s1"},
            trip: %Trip{headsign: "other1", pattern_headsign: "h1", direction_id: 0}
          },
          schedule: nil
        },
        %Departure{
          prediction: %Prediction{
            arrival_time: ~U[2024-10-11 12:30:00Z],
            departure_time: ~U[2024-10-11 12:32:00Z],
            route: %Route{id: "r1", line: %Line{id: "l1"}, type: :bus},
            stop: %Stop{id: "s1"},
            trip: %Trip{headsign: "other3", pattern_headsign: "h3", direction_id: 1}
          },
          schedule: nil
        }
      ]

      expected_sections = [
        %Screens.V2.WidgetInstance.Departures.NormalSection{
          header: %ScreensConfig.Departures.Header{
            arrow: nil,
            read_as: nil,
            subtitle: nil,
            title: nil
          },
          layout: %ScreensConfig.Departures.Layout{
            base: nil,
            include_later: false,
            max: nil,
            min: 1
          },
          grouping_type: :time,
          rows: expected_departures
        }
      ]

      config =
        @config
        |> put_primary_departures(primary_departures)

      expect(@rds, :get, fn _primary_departures, @now ->
        [{:ok, [rds_countdown("s1", "l1", "other1", all_departures)]}]
      end)

      expect(@rds, :get, fn _secondary_departures, @now ->
        [{:ok, []}]
      end)

      expected_instances =
        expected_departures_widget(config, expected_sections, expected_sections)

      actual_instances = DupNew.Departures.instances(config, @now)

      assert actual_instances == expected_instances
    end
  end
end
