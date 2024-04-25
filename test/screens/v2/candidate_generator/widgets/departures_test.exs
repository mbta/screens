defmodule Screens.V2.CandidateGenerator.Widgets.DeparturesTest do
  use ExUnit.Case, async: true

  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Departures.Filters.RouteDirections
  alias ScreensConfig.V2.Departures.Filters.RouteDirections.RouteDirection
  alias ScreensConfig.V2.Departures.{Filters, Query, Section}
  alias ScreensConfig.V2.BusShelter
  alias ScreensConfig.V2.Departures, as: DeparturesConfig
  alias Screens.V2.CandidateGenerator.Widgets.Departures
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, DeparturesNoService, OvernightDepartures}
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Trips.Trip

  defp build_departure(route_id, direction_id, arrival_time \\ ~U[2024-01-01 12:00:00Z]) do
    %Departure{
      prediction: %Prediction{
        route: %Route{id: route_id},
        trip: %Trip{direction_id: direction_id},
        arrival_time: arrival_time
      }
    }
  end

  describe "departures_instances/1" do
    defp build_config(section_route_ids) do
      %Screen{
        app_params: %BusShelter{
          departures: %DeparturesConfig{
            sections:
              Enum.map(
                section_route_ids,
                &%Section{query: %Query{params: %Query.Params{route_ids: [&1]}}}
              )
          },
          header: nil,
          footer: nil,
          alerts: nil
        },
        vendor: nil,
        device_id: nil,
        name: nil,
        app_id: :bus_shelter_v2
      }
    end

    defp build_fetch_fn(route_ids_to_results) do
      fn %{route_ids: [route_id]}, _opts ->
        Map.fetch!(route_ids_to_results, route_id)
      end
    end

    test "returns DeparturesWidget when all section requests succeed with departure data" do
      config = build_config(["A", "B"])
      departures_a = [build_departure("A", 0), build_departure("A", 1)]
      departures_b = [build_departure("B", 0), build_departure("B", 1)]
      fetch_fn = build_fetch_fn(%{"A" => {:ok, departures_a}, "B" => {:ok, departures_b}})

      expected_departures_instances = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{type: :normal_section, rows: departures_a},
            %{type: :normal_section, rows: departures_b}
          ]
        }
      ]

      actual_departures_instances =
        Departures.departures_instances(config, departure_fetch_fn: fetch_fn)

      assert expected_departures_instances == actual_departures_instances
    end

    test "returns DeparturesWidget when all section requests succeed with empty departures" do
      config = build_config(["A", "B"])
      fetch_fn = build_fetch_fn(%{"A" => {:ok, []}, "B" => {:ok, []}})

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
        Departures.departures_instances(config, departure_fetch_fn: fetch_fn)

      assert expected_departures_instances == actual_departures_instances
    end

    test "returns DeparturesNoData if any section request fails" do
      config = build_config(["A", "B"])
      fetch_fn = build_fetch_fn(%{"A" => {:ok, []}, "B" => :error})

      expected_departures_instances = [
        %DeparturesNoData{screen: config, show_alternatives?: true}
      ]

      actual_departures_instances =
        Departures.departures_instances(config, departure_fetch_fn: fetch_fn)

      assert expected_departures_instances == actual_departures_instances
    end

    test "returns DeparturesNoService for bus e-ink when there is a single empty section" do
      config = %Screen{build_config(["E"]) | app_id: :bus_eink_v2}
      fetch_fn = build_fetch_fn(%{"E" => {:ok, []}})

      expected_departures_instances = [%DeparturesNoService{screen: config}]

      actual_departures_instances =
        Departures.departures_instances(config, departure_fetch_fn: fetch_fn)

      assert expected_departures_instances == actual_departures_instances
    end

    test "returns OvernightDepartures if post-process result is [:overnight]" do
      config = build_config(["A", "B"])
      fetch_fn = build_fetch_fn(%{"A" => {:ok, []}, "B" => {:ok, []}})
      post_fn = fn [{:ok, []}, {:ok, []}], _config -> [:overnight] end

      expected_departures_instances = [%OvernightDepartures{}]

      actual_departures_instances =
        Departures.departures_instances(
          config,
          departure_fetch_fn: fetch_fn,
          post_process_fn: post_fn
        )

      assert expected_departures_instances == actual_departures_instances
    end

    test "returns DeparturesWidget with results from post processing" do
      config = build_config(["A", "B"])
      departure_b = build_departure("B", 0)
      fetch_fn = build_fetch_fn(%{"A" => {:ok, []}, "B" => {:ok, [departure_b]}})

      post_process_fn = fn sections, _config ->
        Enum.map(sections, fn {:ok, departures} ->
          {:ok, departures ++ ["notice"]}
        end)
      end

      expected_departures_instances = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{type: :normal_section, rows: ["notice"]},
            %{type: :normal_section, rows: [departure_b, "notice"]}
          ]
        }
      ]

      actual_departures_instances =
        Departures.departures_instances(
          config,
          departure_fetch_fn: fetch_fn,
          post_process_fn: post_process_fn
        )

      assert expected_departures_instances == actual_departures_instances
    end
  end

  describe "fetch_section_departures/1" do
    test "filters departures by time when a section has a max_minutes" do
      now = ~U[2024-01-01 12:00:00Z]

      section = %Section{
        query: %Query{params: %Query.Params{stop_ids: ["S"]}},
        filters: %Filters{max_minutes: 60}
      }

      included_departures = [
        build_departure("1", 0, DateTime.add(now, 59, :minute)),
        build_departure("1", 0, DateTime.add(now, 60, :minute))
      ]

      fetch_fn = fn %{stop_ids: ["S"]}, _ ->
        {:ok, [build_departure("1", 0, DateTime.add(now, 61, :minute)) | included_departures]}
      end

      assert {:ok, included_departures} ==
               Departures.fetch_section_departures(section, fetch_fn, now)
    end

    test "filters departures with included route-directions" do
      section = %Section{
        query: %Query{params: %Query.Params{stop_ids: ["S"]}},
        filters: %Filters{
          route_directions: %RouteDirections{
            action: :include,
            targets: [
              %RouteDirection{route_id: "39", direction_id: 0},
              %RouteDirection{route_id: "41", direction_id: 0}
            ]
          }
        }
      }

      included_departure = build_departure("41", 0)

      fetch_fn = fn %{stop_ids: ["S"]}, _ ->
        {:ok, [build_departure("41", 1), included_departure, build_departure("1", 1)]}
      end

      assert {:ok, [included_departure]} == Departures.fetch_section_departures(section, fetch_fn)
    end

    test "rejects departures with excluded route-directions" do
      section = %Section{
        query: %Query{params: %Query.Params{stop_ids: ["S"]}},
        filters: %Filters{
          route_directions: %RouteDirections{
            action: :exclude,
            targets: [
              %RouteDirection{route_id: "39", direction_id: 0},
              %RouteDirection{route_id: "41", direction_id: 0}
            ]
          }
        }
      }

      included_departures = [build_departure("41", 1), build_departure("1", 1)]

      fetch_fn = fn %{stop_ids: ["S"]}, _ ->
        {:ok, [build_departure("41", 0) | included_departures]}
      end

      assert {:ok, included_departures} ==
               Departures.fetch_section_departures(section, fetch_fn)
    end

    test "filters departures for sections configured as bidirectional" do
      config = build_config([])

      config =
        put_in(config.app_params.departures.sections, [
          %Section{query: %Query{params: %Query.Params{route_ids: ["A"]}}, bidirectional: true},
          %Section{query: %Query{params: %Query.Params{route_ids: ["B"]}}}
        ])

      fetch_fn =
        build_fetch_fn(%{
          "A" =>
            {:ok,
             [
               # take
               build_departure("A", 0),
               # filter out: same as first
               build_departure("A", 0),
               # take
               build_departure("A", 1),
               # filter out: same as first
               build_departure("A", 0)
             ]},
          "B" => {:ok, [build_departure("B", 0), build_departure("B", 0)]}
        })

      expected_departures_instances = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{type: :normal_section, rows: [build_departure("A", 0), build_departure("A", 1)]},
            %{type: :normal_section, rows: [build_departure("B", 0), build_departure("B", 0)]}
          ]
        }
      ]

      actual_departures_instances =
        Departures.departures_instances(config, departure_fetch_fn: fetch_fn)

      assert expected_departures_instances == actual_departures_instances
    end
  end
end
