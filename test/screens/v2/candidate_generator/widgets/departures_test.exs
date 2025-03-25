defmodule Screens.V2.CandidateGenerator.Widgets.DeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Trips.Trip
  alias Screens.V2.CandidateGenerator.Widgets.Departures
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.Departures.NormalSection
  alias Screens.V2.WidgetInstance.{DeparturesNoData, DeparturesNoService, OvernightDepartures}
  alias ScreensConfig.Departures.Filters.RouteDirections
  alias ScreensConfig.Departures.Filters.RouteDirections.RouteDirection
  alias ScreensConfig.Departures.{Filters, Header, Layout, Query, Section}
  alias ScreensConfig.Departures, as: DeparturesConfig
  alias ScreensConfig.FreeTextLine
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.BusShelter

  defp build_departure(
         route_id,
         direction_id,
         route_type \\ :bus,
         arrival_time \\ ~U[2024-01-01 12:00:00Z]
       ) do
    %Departure{
      prediction: %Prediction{
        route: %Route{id: route_id, type: route_type},
        trip: %Trip{direction_id: direction_id},
        arrival_time: arrival_time
      }
    }
  end

  describe "departures_instances/3" do
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

    defp departures_instances(config, options) do
      Departures.departures_instances(
        config,
        nil,
        Keyword.merge(
          [
            departure_fetch_fn: fn _, _ -> :error end,
            route_fetch_fn: fn _ -> :error end
          ],
          options
        )
      )
    end

    test "returns DeparturesWidget when all section requests succeed with departure data" do
      config = build_config(["A", "B"])
      departures_a = [build_departure("A", 0), build_departure("A", 1)]
      departures_b = [build_departure("B", 0), build_departure("B", 1)]
      fetch_fn = build_fetch_fn(%{"A" => {:ok, departures_a}, "B" => {:ok, departures_b}})

      assert [
               %DeparturesWidget{
                 screen: ^config,
                 sections: [
                   %NormalSection{rows: ^departures_a},
                   %NormalSection{rows: ^departures_b}
                 ]
               }
             ] = departures_instances(config, departure_fetch_fn: fetch_fn)
    end

    test "passes layout field from the config through to the returned sections" do
      config = build_config(["A"])
      fetch_fn = build_fetch_fn(%{"A" => {:ok, []}})
      layout = %Layout{min: 2, base: 4, max: 6, include_later: true}

      config =
        put_in(config.app_params.departures.sections, [
          %Section{query: %Query{params: %Query.Params{route_ids: ["A"]}}, layout: layout}
        ])

      assert [
               %DeparturesWidget{screen: ^config, sections: [%{layout: ^layout}]}
             ] = departures_instances(config, departure_fetch_fn: fetch_fn)
    end

    test "passes header field from the config through to the returned sections" do
      config = build_config(["A"])
      fetch_fn = build_fetch_fn(%{"A" => {:ok, []}})
      header = %Header{title: "Test Header 1", arrow: :sw}

      config =
        put_in(config.app_params.departures.sections, [
          %Section{query: %Query{params: %Query.Params{route_ids: ["A"]}}, header: header}
        ])

      assert [%DeparturesWidget{sections: [%{header: ^header}]}] =
               departures_instances(config, departure_fetch_fn: fetch_fn)
    end

    test "with multiple sections, returns DeparturesWidget with notice rows in empty sections" do
      config = build_config(["A", "B"])
      departure_b = build_departure("B", 0)
      departure_fetch_fn = build_fetch_fn(%{"A" => {:ok, []}, "B" => {:ok, [departure_b]}})
      route_fetch_fn = fn %{ids: ["A"]} -> {:ok, [%Route{id: "A", type: :bus}]} end

      assert [
               %DeparturesWidget{
                 sections: [
                   %NormalSection{
                     rows: [
                       %FreeTextLine{
                         icon: :bus,
                         text: ["No departures currently available"]
                       }
                     ]
                   },
                   %NormalSection{rows: [^departure_b]}
                 ]
               }
             ] =
               departures_instances(config,
                 departure_fetch_fn: departure_fetch_fn,
                 route_fetch_fn: route_fetch_fn
               )
    end

    test "with multiple sections, returns notice row with no icon if no routes are found" do
      config = build_config(["A", "B"])
      departure_b = build_departure("B", 0)
      departure_fetch_fn = build_fetch_fn(%{"A" => {:ok, []}, "B" => {:ok, [departure_b]}})
      route_fetch_fn = fn %{ids: ["A"]} -> {:ok, []} end

      assert [
               %DeparturesWidget{
                 sections: [
                   %NormalSection{
                     rows: [
                       %FreeTextLine{
                         icon: nil,
                         text: ["No departures currently available"]
                       }
                     ]
                   },
                   %NormalSection{rows: [^departure_b]}
                 ]
               }
             ] =
               departures_instances(config,
                 departure_fetch_fn: departure_fetch_fn,
                 route_fetch_fn: route_fetch_fn
               )
    end

    test "with multiple sections, returns a notice row when a mode is devops-disabled" do
      # use a screen type that does not get entirely disabled based on mode
      config = %Screen{build_config(["A", "B"]) | app_id: :busway_v2}
      departure_b = build_departure("B", 0, :subway)

      departure_fetch_fn =
        build_fetch_fn(%{"A" => {:ok, [build_departure("A", 0)]}, "B" => {:ok, [departure_b]}})

      disabled_modes_fn = fn -> [:bus] end
      route_fetch_fn = fn %{ids: ["A"]} -> {:ok, [%Route{id: "A", type: :bus}]} end

      assert [
               %DeparturesWidget{
                 sections: [
                   %NormalSection{
                     rows: [
                       %FreeTextLine{
                         icon: :bus,
                         text: ["No departures currently available"]
                       }
                     ]
                   },
                   %NormalSection{rows: [^departure_b]}
                 ]
               }
             ] =
               departures_instances(config,
                 departure_fetch_fn: departure_fetch_fn,
                 disabled_modes_fn: disabled_modes_fn,
                 route_fetch_fn: route_fetch_fn
               )
    end

    test "returns DeparturesNoData if any section request fails" do
      config = build_config(["A", "B"])
      fetch_fn = build_fetch_fn(%{"A" => {:ok, []}, "B" => :error})

      expected_departures_instances = [
        %DeparturesNoData{screen: config, show_alternatives?: true}
      ]

      actual_departures_instances = departures_instances(config, departure_fetch_fn: fetch_fn)

      assert expected_departures_instances == actual_departures_instances
    end

    test "returns DeparturesNoData if the mode for the screen type is devops-disabled" do
      config = %Screen{build_config(["A"]) | app_id: :gl_eink_v2}
      fetch_fn = build_fetch_fn(%{"A" => {:ok, []}})
      disabled_modes_fn = fn -> [:light_rail] end

      assert [%DeparturesNoData{screen: config, show_alternatives?: false}] ==
               departures_instances(config,
                 departure_fetch_fn: fetch_fn,
                 disabled_modes_fn: disabled_modes_fn
               )
    end

    test "returns DeparturesNoService for bus e-ink when there is a single empty section" do
      config = %Screen{build_config(["E"]) | app_id: :bus_eink_v2}
      fetch_fn = build_fetch_fn(%{"E" => {:ok, []}})

      expected_departures_instances = [%DeparturesNoService{screen: config}]
      actual_departures_instances = departures_instances(config, departure_fetch_fn: fetch_fn)

      assert expected_departures_instances == actual_departures_instances
    end

    test "returns OvernightDepartures if post-process result is :overnight" do
      config = build_config(["A"])
      fetch_fn = build_fetch_fn(%{"A" => {:ok, []}})
      post_fn = fn {:ok, []}, _config -> :overnight end

      expected_departures_instances = [%OvernightDepartures{}]

      actual_departures_instances =
        departures_instances(
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

      post_process_fn = fn {:ok, departures}, _config ->
        {:ok, departures ++ ["notice"]}
      end

      assert [
               %DeparturesWidget{
                 screen: ^config,
                 sections: [
                   %NormalSection{rows: ["notice"]},
                   %NormalSection{rows: [^departure_b, "notice"]}
                 ]
               }
             ] =
               departures_instances(config,
                 departure_fetch_fn: fetch_fn,
                 post_process_fn: post_process_fn
               )
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
        build_departure("1", 0, nil, DateTime.add(now, 59, :minute)),
        build_departure("1", 0, nil, DateTime.add(now, 60, :minute))
      ]

      fetch_fn = fn %{stop_ids: ["S"]}, _ ->
        {:ok,
         [build_departure("1", 0, nil, DateTime.add(now, 61, :minute)) | included_departures]}
      end

      assert {:ok, included_departures} ==
               Departures.fetch_section_departures(section, [], fetch_fn, now)
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

      assert {:ok, [included_departure]} ==
               Departures.fetch_section_departures(section, [], fetch_fn)
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
               Departures.fetch_section_departures(section, [], fetch_fn)
    end

    test "filters departures for sections configured as bidirectional" do
      config = build_config([])

      config =
        put_in(config.app_params.departures.sections, [
          %Section{query: %Query{params: %Query.Params{route_ids: ["A"]}}, bidirectional: true},
          %Section{query: %Query{params: %Query.Params{route_ids: ["B"]}}}
        ])

      departure_a_0 = build_departure("A", 0)
      departure_a_1 = build_departure("A", 1)
      departure_b_0 = build_departure("B", 0)

      fetch_fn =
        build_fetch_fn(%{
          "A" =>
            {:ok,
             [
               # take
               departure_a_0,
               # filter out: same as first
               departure_a_0,
               # take
               departure_a_1,
               # filter out: same as first
               departure_a_0
             ]},
          "B" => {:ok, [departure_b_0, departure_b_0]}
        })

      assert [
               %DeparturesWidget{
                 screen: ^config,
                 sections: [
                   %{rows: [^departure_a_0, ^departure_a_1]},
                   %{rows: [^departure_b_0, ^departure_b_0]}
                 ]
               }
             ] = departures_instances(config, departure_fetch_fn: fetch_fn)
    end
  end
end
