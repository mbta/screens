defmodule Screens.V2.CandidateGenerator.Dup.DeparturesHeadwayTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V2.CandidateGenerator.Dup
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.Departures.{HeadwaySection, NormalSection}
  alias Screens.Vehicles.Vehicle
  alias ScreensConfig.{Alerts, Departures, Header}
  alias ScreensConfig.Departures.Header, as: SectionHeader
  alias ScreensConfig.Departures.{Layout, Query, Section}
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.Dup, as: DupConfig

  import Screens.Inject
  import Mox
  setup :verify_on_exit!

  @headways injected(Screens.Headways)

  defp put_primary_departures(widget, primary_departures_sections) do
    %{
      widget
      | app_params: %{
          widget.app_params
          | primary_departures: %Departures{sections: primary_departures_sections}
        }
    }
  end

  setup do
    config = %Screen{
      app_params: %DupConfig{
        header: %Header.StopId{stop_id: "place-headway-test"},
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

    fetch_departures_fn = fn
      %{stop_ids: ["place-A"]}, _opts ->
        {:ok,
         [
           %Departure{
             prediction:
               struct(Prediction,
                 id: "A",
                 route: %Route{id: "Test"},
                 stop: struct(Stop),
                 trip: struct(Trip)
               )
           }
         ]}

      _, _ ->
        {:ok, []}
    end

    fetch_alerts_fn = fn
      _ -> []
    end

    fetch_schedules_fn = fn
      _, _ ->
        []
    end

    fetch_vehicles_fn = fn _, _ -> [struct(Vehicle)] end

    fetch_routes_fn = fn
      %{ids: ids} ->
        {
          :ok,
          ids
          |> Enum.flat_map(fn
            "Ferry" ->
              [%{id: "Ferry", type: :ferry}]

            "Orange" ->
              [%{id: "Orange", type: :subway}]

            "Green" ->
              [%{id: "Green", type: :light_rail}]

            "Red" ->
              [%{id: "Red", type: :subway}]

            "Blue" ->
              [
                %Route{
                  id: "Blue",
                  type: :subway,
                  direction_names: ["Test Direction Zero", "Test Direction One"]
                }
              ]

            "743" ->
              [%Route{id: "743", type: :bus, direction_names: ["Test Bus One", "Test Bus Two"]}]
          end)
          |> Enum.uniq()
        }

      %{stop_ids: stop_ids} ->
        {
          :ok,
          stop_ids
          |> Enum.flat_map(fn
            "place-knncl" ->
              [%{id: "Red", type: :subway}]

            "place-A" ->
              [%{id: "Orange", type: :subway}, %{id: "Green", type: :light_rail}]

            _ ->
              [%{id: "test", type: :test}]
          end)
          |> Enum.uniq()
        }
    end

    %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_fn: fetch_routes_fn,
      fetch_vehicles_fn: fetch_vehicles_fn
    }
  end

  test "returns headway section when no departures, no alert and not in overnight period", %{
    config: config,
    fetch_departures_fn: fetch_departures_fn,
    fetch_alerts_fn: fetch_alerts_fn,
    fetch_schedules_fn: fetch_schedules_fn,
    fetch_routes_fn: fetch_routes_fn,
    fetch_vehicles_fn: fetch_vehicles_fn
  } do
    config =
      put_primary_departures(config, [
        %Section{query: %Query{params: %Query.Params{stop_ids: ["place-knncl"]}}}
      ])

    now = ~U[2020-04-06T10:00:00Z]
    expect(@headways, :get_with_route, fn "place-knncl", "Red", ^now -> {12, 16} end)

    expected_departures = [
      %DeparturesWidget{
        screen: config,
        sections: [
          %HeadwaySection{
            route: "Red",
            time_range: {12, 16},
            headsign: nil
          }
        ],
        slot_names: [:main_content_zero],
        now: now
      },
      %DeparturesWidget{
        screen: config,
        sections: [
          %HeadwaySection{
            route: "Red",
            time_range: {12, 16},
            headsign: nil
          }
        ],
        slot_names: [:main_content_one],
        now: now
      },
      %DeparturesWidget{
        screen: config,
        sections: [
          %HeadwaySection{
            route: "Red",
            time_range: {12, 16},
            headsign: nil
          }
        ],
        slot_names: [:main_content_two],
        now: now
      }
    ]

    actual_instances =
      Dup.Departures.departures_instances(
        config,
        now,
        fetch_departures_fn,
        fetch_alerts_fn,
        fetch_schedules_fn,
        fetch_routes_fn,
        fetch_vehicles_fn
      )

    assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
  end

  test "returns headway sections with direction names if the sections are configured with direction_id",
       %{
         config: config,
         fetch_departures_fn: fetch_departures_fn,
         fetch_alerts_fn: fetch_alerts_fn,
         fetch_schedules_fn: fetch_schedules_fn,
         fetch_routes_fn: fetch_routes_fn,
         fetch_vehicles_fn: fetch_vehicles_fn
       } do
    config =
      put_primary_departures(config, [
        %Section{
          query: %Query{
            params: %Query.Params{stop_ids: ["place-aport"], route_ids: ["Blue"], direction_id: 0}
          }
        },
        %Section{
          query: %Query{
            params: %Query.Params{stop_ids: ["place-aport"], route_ids: ["743"], direction_id: 0}
          }
        }
      ])

    now = ~U[2020-04-06T10:00:00Z]
    expect(@headways, :get_with_route, fn "place-aport", "Blue", ^now -> {2, 4} end)
    expect(@headways, :get_with_route, fn "place-aport", "743", ^now -> {6, 8} end)

    expected_departures = [
      %DeparturesWidget{
        screen: config,
        sections: [
          %HeadwaySection{
            route: "Blue",
            time_range: {2, 4},
            headsign: "Test Direction Zero"
          },
          %HeadwaySection{
            route: "743",
            time_range: {6, 8},
            headsign: "Test Bus One"
          }
        ],
        slot_names: [:main_content_zero],
        now: now
      },
      %DeparturesWidget{
        screen: config,
        sections: [
          %HeadwaySection{
            route: "Blue",
            time_range: {2, 4},
            headsign: "Test Direction Zero"
          },
          %HeadwaySection{
            route: "743",
            time_range: {6, 8},
            headsign: "Test Bus One"
          }
        ],
        slot_names: [:main_content_one],
        now: now
      },
      %DeparturesWidget{
        screen: config,
        sections: [
          %HeadwaySection{
            route: "Blue",
            time_range: {2, 4},
            headsign: "Test Direction Zero"
          },
          %HeadwaySection{
            route: "743",
            time_range: {6, 8},
            headsign: "Test Bus One"
          }
        ],
        slot_names: [:main_content_two],
        now: now
      }
    ]

    actual_instances =
      Dup.Departures.departures_instances(
        config,
        now,
        fetch_departures_fn,
        fetch_alerts_fn,
        fetch_schedules_fn,
        fetch_routes_fn,
        fetch_vehicles_fn
      )

    assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
  end

  test "returns directional headway when at boundary for alerts", %{
    config: config,
    fetch_departures_fn: fetch_departures_fn,
    fetch_schedules_fn: fetch_schedules_fn,
    fetch_routes_fn: fetch_routes_fn,
    fetch_vehicles_fn: fetch_vehicles_fn
  } do
    config =
      put_primary_departures(config, [
        %Section{query: %Query{params: %Query.Params{stop_ids: ["place-B"]}}}
      ])

    now = ~U[2020-04-06T10:00:00Z]
    expect(@headways, :get_with_route, fn "place-B", "test", ^now -> {12, 16} end)

    fetch_alerts_fn = fn
      [
        direction_id: :both,
        route_ids: [],
        stop_ids: ["place-B"],
        route_types: [:light_rail, :subway]
      ] ->
        [
          struct(Alert,
            effect: :suspension,
            informed_entities: [
              %{stop: "place-B", route: "Red"}
            ],
            active_period: [{~U[2020-04-06T09:00:00Z], nil}]
          )
        ]
    end

    expected_departures = [
      %DeparturesWidget{
        screen: config,
        sections: [
          %HeadwaySection{
            route: "Red",
            time_range: {12, 16},
            headsign: "Test A"
          }
        ],
        slot_names: [:main_content_zero],
        now: now
      },
      %DeparturesWidget{
        screen: config,
        sections: [
          %HeadwaySection{
            route: "Red",
            time_range: {12, 16},
            headsign: "Test A"
          }
        ],
        slot_names: [:main_content_one],
        now: now
      },
      %DeparturesWidget{
        screen: config,
        sections: [
          %HeadwaySection{
            route: "Red",
            time_range: {12, 16},
            headsign: "Test A"
          }
        ],
        slot_names: [:main_content_two],
        now: now
      }
    ]

    actual_instances =
      Dup.Departures.departures_instances(
        config,
        now,
        fetch_departures_fn,
        fetch_alerts_fn,
        fetch_schedules_fn,
        fetch_routes_fn,
        fetch_vehicles_fn
      )

    assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
  end

  test "returns headway section and regular predictions when multiple departures configured but one section has headways",
       %{
         config: config,
         fetch_departures_fn: fetch_departures_fn,
         fetch_alerts_fn: fetch_alerts_fn,
         fetch_schedules_fn: fetch_schedules_fn,
         fetch_routes_fn: fetch_routes_fn,
         fetch_vehicles_fn: fetch_vehicles_fn
       } do
    config =
      put_primary_departures(config, [
        %Section{query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}},
        %Section{query: %Query{params: %Query.Params{stop_ids: ["place-kencl"]}}}
      ])

    now = ~U[2020-04-06T10:00:00Z]
    expect(@headways, :get_with_route, fn "place-A", "Orange", ^now -> nil end)
    expect(@headways, :get_with_route, fn "place-A", "Green", ^now -> nil end)
    expect(@headways, :get_with_route, fn "place-kencl", "test", ^now -> {7, 13} end)

    expected_departures = [
      %DeparturesWidget{
        screen: config,
        sections: [
          %NormalSection{
            layout: %Layout{},
            header: %SectionHeader{},
            rows: [
              %Screens.V2.Departure{
                prediction:
                  struct(Prediction,
                    id: "A",
                    route: %Route{id: "Test"},
                    stop: struct(Stop),
                    trip: struct(Trip)
                  ),
                schedule: nil
              }
            ]
          },
          %HeadwaySection{
            route: "test",
            time_range: {7, 13},
            headsign: nil
          }
        ],
        slot_names: [:main_content_reduced_zero],
        now: now
      },
      %DeparturesWidget{
        screen: config,
        sections: [
          %NormalSection{
            layout: %Layout{},
            header: %SectionHeader{},
            rows: [
              %Screens.V2.Departure{
                prediction:
                  struct(Prediction,
                    id: "A",
                    route: %Route{id: "Test"},
                    stop: struct(Stop),
                    trip: struct(Trip)
                  ),
                schedule: nil
              }
            ]
          },
          %HeadwaySection{
            route: "test",
            time_range: {7, 13},
            headsign: nil
          }
        ],
        slot_names: [:main_content_reduced_one],
        now: now
      },
      %DeparturesWidget{
        screen: config,
        sections: [
          %NormalSection{
            layout: %Layout{},
            header: %SectionHeader{},
            rows: [
              %Screens.V2.Departure{
                prediction:
                  struct(Prediction,
                    id: "A",
                    route: %Route{id: "Test"},
                    stop: struct(Stop),
                    trip: struct(Trip)
                  ),
                schedule: nil
              }
            ]
          },
          %HeadwaySection{
            route: "test",
            time_range: {7, 13},
            headsign: nil
          }
        ],
        slot_names: [:main_content_reduced_two],
        now: now
      }
    ]

    actual_instances =
      Dup.Departures.departures_instances(
        config,
        now,
        fetch_departures_fn,
        fetch_alerts_fn,
        fetch_schedules_fn,
        fetch_routes_fn,
        fetch_vehicles_fn
      )

    assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
  end

  test "returns headway sections for branch station for alert with trunk headsign", %{
    config: config,
    fetch_departures_fn: fetch_departures_fn,
    fetch_schedules_fn: fetch_schedules_fn,
    fetch_routes_fn: fetch_routes_fn,
    fetch_vehicles_fn: fetch_vehicles_fn
  } do
    config =
      put_primary_departures(config, [
        %Section{query: %Query{params: %Query.Params{stop_ids: ["place-kencl"]}}}
      ])

    now = ~U[2020-04-06T10:00:00Z]
    expect(@headways, :get_with_route, fn "place-kencl", "test", ^now -> {7, 13} end)

    fetch_alerts_fn = fn
      [
        direction_id: :both,
        route_ids: [],
        stop_ids: ["place-kencl"],
        route_types: [:light_rail, :subway]
      ] ->
        [
          # Suspension alert from Kenmore to Hynes
          struct(Alert,
            effect: :suspension,
            informed_entities: [
              %{
                direction_id: nil,
                facility: nil,
                route: "Green-C",
                route_type: 0,
                stop: "70151"
              },
              %{
                direction_id: nil,
                facility: nil,
                route: "Green-C",
                route_type: 0,
                stop: "70152"
              },
              %{
                direction_id: nil,
                facility: nil,
                route: "Green-C",
                route_type: 0,
                stop: "place-kencl"
              },
              %{
                direction_id: nil,
                facility: nil,
                route: "Green-C",
                route_type: 0,
                stop: "place-hymnl"
              }
            ],
            active_period: [{~U[2020-04-06T09:00:00Z], nil}]
          )
        ]
    end

    expected_departures = [
      %DeparturesWidget{
        screen: config,
        sections: [
          %HeadwaySection{
            route: "Green-C",
            time_range: {7, 13},
            headsign: "Westbound"
          }
        ],
        slot_names: [:main_content_reduced_zero],
        now: now
      },
      %DeparturesWidget{
        screen: config,
        sections: [
          %HeadwaySection{
            route: "Green-C",
            time_range: {7, 13},
            headsign: "Westbound"
          }
        ],
        slot_names: [:main_content_reduced_one],
        now: now
      },
      %DeparturesWidget{
        screen: config,
        sections: [
          %HeadwaySection{
            route: "Green-C",
            time_range: {7, 13},
            headsign: "Westbound"
          }
        ],
        slot_names: [:main_content_reduced_two],
        now: now
      }
    ]

    actual_instances =
      Dup.Departures.departures_instances(
        config,
        now,
        fetch_departures_fn,
        fetch_alerts_fn,
        fetch_schedules_fn,
        fetch_routes_fn,
        fetch_vehicles_fn
      )

    assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
  end
end
