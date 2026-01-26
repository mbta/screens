defmodule Screens.V2.CandidateGenerator.Dup.DeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V2.CandidateGenerator.Dup
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.Departures.{NoDataSection, NormalSection}
  alias Screens.V2.WidgetInstance.DeparturesNoData
  alias Screens.V2.WidgetInstance.OvernightDepartures
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

  defp put_secondary_departures_sections(widget, secondary_departures_sections) do
    %{
      widget
      | app_params: %{
          widget.app_params
          | secondary_departures: %Departures{sections: secondary_departures_sections}
        }
    }
  end

  setup do
    stub(Screens.Headways.Mock, :get_with_route, fn _, _, _ -> nil end)

    config = %Screen{
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

      %{stop_ids: ["place-B"]}, _opts ->
        {:ok,
         [
           %Departure{
             prediction:
               struct(Prediction,
                 id: "B1",
                 route: %Route{id: "Test"},
                 stop: struct(Stop),
                 trip: struct(Trip)
               )
           },
           %Departure{
             prediction:
               struct(Prediction,
                 id: "B2",
                 route: %Route{id: "Test"},
                 stop: struct(Stop),
                 trip: struct(Trip)
               )
           },
           %Departure{
             prediction:
               struct(Prediction,
                 id: "B3",
                 route: %Route{id: "Test"},
                 stop: struct(Stop),
                 trip: struct(Trip)
               )
           },
           %Departure{
             prediction:
               struct(Prediction,
                 id: "B4",
                 route: %Route{id: "Test"},
                 stop: struct(Stop),
                 trip: struct(Trip)
               )
           },
           %Departure{
             prediction:
               struct(Prediction,
                 id: "B5",
                 route: %Route{id: "Test"},
                 stop: struct(Stop),
                 trip: struct(Trip)
               )
           }
         ]}

      %{stop_ids: ["place-C"]}, _opts ->
        {:ok,
         [
           %Departure{
             prediction:
               struct(Prediction,
                 id: "C",
                 route: %Route{id: "Test"},
                 stop: struct(Stop),
                 trip: struct(Trip)
               )
           }
         ]}

      %{stop_ids: ["place-D"]}, _opts ->
        {:ok,
         [
           %Departure{
             prediction:
               struct(Prediction,
                 id: "D",
                 route: %Route{id: "Test"},
                 stop: struct(Stop),
                 trip: struct(Trip)
               )
           }
         ]}

      %{stop_ids: ["place-F"]}, _opts ->
        {:ok,
         [
           %Departure{
             prediction: %Prediction{
               id: "F1",
               trip: %Trip{direction_id: 0},
               stop: struct(Stop),
               route: %Route{id: "Test"}
             }
           },
           %Departure{
             prediction: %Prediction{
               id: "F2",
               trip: %Trip{direction_id: 0},
               stop: struct(Stop),
               route: %Route{id: "Test"}
             }
           },
           %Departure{
             prediction: %Prediction{
               id: "F3",
               trip: %Trip{direction_id: 0},
               stop: struct(Stop),
               route: %Route{id: "Test"}
             }
           },
           %Departure{
             prediction: %Prediction{
               id: "F4",
               trip: %Trip{direction_id: 1},
               stop: struct(Stop),
               route: %Route{id: "Test"}
             }
           },
           %Departure{
             prediction: %Prediction{
               id: "F5",
               trip: %Trip{direction_id: 1},
               stop: struct(Stop),
               route: %Route{id: "Test"}
             }
           }
         ]}

      %{stop_ids: ["place-G"]}, _opts ->
        {:ok,
         [
           %Departure{
             prediction: %Prediction{
               id: "G1",
               trip: %Trip{direction_id: 1},
               stop: struct(Stop),
               route: %Route{id: "Test"}
             }
           }
         ]}

      %{stop_ids: ["place-kencl"]}, _opts ->
        {:ok,
         [
           %Departure{
             prediction:
               struct(Prediction,
                 id: "Kenmore",
                 route: %Route{id: "Test"},
                 stop: struct(Stop),
                 trip: struct(Trip)
               )
           }
         ]}

      %{stop_ids: ["bus-A", "bus-B"]}, _opts ->
        {:ok,
         [
           %Departure{
             prediction:
               struct(Prediction,
                 id: "Bus A",
                 route: %Route{id: "Bus A", type: :bus},
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
            "Ferry" -> [%{id: "Ferry", type: :ferry}]
            "Orange" -> [%{id: "Orange", type: :subway}]
            "Green" -> [%{id: "Green", type: :light_rail}]
            "Bus A" -> [%{id: "Bus A", type: :bus}]
            "Bus B" -> [%{id: "Bus B", type: :bus}]
            "Bus C" -> [%{id: "Bus C", type: :bus}]
            "Red" -> [%{id: "Red", type: :subway}]
          end)
          |> Enum.uniq()
        }

      %{stop_ids: stop_ids} ->
        {
          :ok,
          stop_ids
          |> Enum.flat_map(fn
            "Boat" -> [%{id: "Ferry", type: :ferry}]
            "place-A" -> [%{id: "Orange", type: :subway}, %{id: "Green", type: :light_rail}]
            "bus-A" -> [%{id: "Bus A", type: :bus}]
            "bus-B" -> [%{id: "Bus B", type: :bus}]
            "bus-C" -> [%{id: "Bus C", type: :bus}]
            "bus-C+D" -> [%{id: "Bus C", type: :bus}, %{id: "Bus D", type: :bus}]
            "place-overnight" -> [%{id: "Red", type: :subway}]
            "place-closed" -> [%{id: "Red", type: :subway}, %{id: "Bus A", type: :bus}]
            _ -> [%{id: "test", type: :test}]
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

  describe "departures_instances/4" do
    test "returns primary and secondary departures", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_fn: fetch_routes_fn,
      fetch_vehicles_fn: fetch_vehicles_fn
    } do
      config =
        config
        |> put_primary_departures([
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}},
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-B"]}}}
        ])
        |> put_secondary_departures_sections([
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-C"]}}},
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-D"]}}}
        ])

      now = ~U[2020-04-06T10:00:00Z]

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
            %NormalSection{
              layout: %Layout{},
              header: %SectionHeader{},
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B1",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B2",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          slot_names: [:main_content_zero],
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
            %NormalSection{
              layout: %Layout{},
              header: %SectionHeader{},
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B1",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B2",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          slot_names: [:main_content_one],
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
                      id: "C",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
            },
            %NormalSection{
              layout: %Layout{},
              header: %SectionHeader{},
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "D",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
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

    test "returns only primary departures if secondary is missing", %{
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
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-B"]}}}
        ])

      now = ~U[2020-04-06T10:00:00Z]

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
            %NormalSection{
              layout: %Layout{},
              header: %SectionHeader{},
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B1",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B2",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          slot_names: [:main_content_zero],
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
            %NormalSection{
              layout: %Layout{},
              header: %SectionHeader{},
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B1",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B2",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          slot_names: [:main_content_one],
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
            %NormalSection{
              layout: %Layout{},
              header: %SectionHeader{},
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B1",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B2",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
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

    test "returns only primary departures if secondary has no data", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_fn: fetch_routes_fn,
      fetch_vehicles_fn: fetch_vehicles_fn
    } do
      config =
        config
        |> put_primary_departures([
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}}
        ])
        |> put_secondary_departures_sections([
          %Section{query: %Query{params: %Query.Params{stop_ids: ["nonexist"]}}}
        ])

      now = ~U[2020-04-06T10:00:00Z]

      primary_section = %NormalSection{
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
      }

      expected_departures = [
        %DeparturesWidget{
          screen: config,
          sections: [primary_section],
          slot_names: [:main_content_zero],
          now: now
        },
        %DeparturesWidget{
          screen: config,
          sections: [primary_section],
          slot_names: [:main_content_one],
          now: now
        },
        %DeparturesWidget{
          screen: config,
          sections: [primary_section],
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

    test "returns only bidirectional departures if configured for that", %{
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
            bidirectional: true,
            query: %Query{params: %Query.Params{stop_ids: ["place-F"]}}
          },
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}}
        ])

      now = ~U[2020-04-06T10:00:00Z]

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
                      id: "F1",
                      trip: struct(Trip, direction_id: 0),
                      stop: struct(Stop),
                      route: %Route{id: "Test"}
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "F4",
                      trip: struct(Trip, direction_id: 1),
                      stop: struct(Stop),
                      route: %Route{id: "Test"}
                    ),
                  schedule: nil
                }
              ]
            },
            %NormalSection{
              layout: %Layout{},
              header: %SectionHeader{},
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "A",
                      stop: struct(Stop),
                      route: %Route{id: "Test"},
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          slot_names: [:main_content_zero],
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
                      id: "F1",
                      trip: struct(Trip, direction_id: 0),
                      stop: struct(Stop),
                      route: %Route{id: "Test"}
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "F4",
                      trip: struct(Trip, direction_id: 1),
                      stop: struct(Stop),
                      route: %Route{id: "Test"}
                    ),
                  schedule: nil
                }
              ]
            },
            %NormalSection{
              layout: %Layout{},
              header: %SectionHeader{},
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "A",
                      stop: struct(Stop),
                      route: %Route{id: "Test"},
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          slot_names: [:main_content_one],
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
                      id: "F1",
                      trip: struct(Trip, direction_id: 0),
                      stop: struct(Stop),
                      route: %Route{id: "Test"}
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "F4",
                      trip: struct(Trip, direction_id: 1),
                      stop: struct(Stop),
                      route: %Route{id: "Test"}
                    ),
                  schedule: nil
                }
              ]
            },
            %NormalSection{
              layout: %Layout{},
              header: %SectionHeader{},
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "A",
                      stop: struct(Stop),
                      route: %Route{id: "Test"},
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
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

    test "returns one row for bidirectional departures if only one departure exists", %{
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
            bidirectional: true,
            query: %Query{params: %Query.Params{stop_ids: ["place-G"]}}
          }
        ])

      now = ~U[2020-04-06T10:00:00Z]

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
                      id: "G1",
                      stop: struct(Stop),
                      route: %Route{id: "Test"},
                      trip: struct(Trip, direction_id: 1)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          slot_names: [:main_content_zero],
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
                      id: "G1",
                      stop: struct(Stop),
                      route: %Route{id: "Test"},
                      trip: struct(Trip, direction_id: 1)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          slot_names: [:main_content_one],
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
                      id: "G1",
                      stop: struct(Stop),
                      route: %Route{id: "Test"},
                      trip: struct(Trip, direction_id: 1)
                    ),
                  schedule: nil
                }
              ]
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

    test "returns 4 departures if only one section", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_fn: fetch_routes_fn,
      fetch_vehicles_fn: fetch_vehicles_fn
    } do
      config =
        put_primary_departures(config, [
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-B"]}}}
        ])

      now = ~U[2020-04-06T10:00:00Z]

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
                      id: "B1",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B2",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B3",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B4",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          slot_names: [:main_content_zero],
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
                      id: "B1",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B2",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B3",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B4",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          slot_names: [:main_content_one],
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
                      id: "B1",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B2",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B3",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B4",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
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

    test "returns normal sections for upcoming alert", %{
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
                %{stop: "place-B", route: "Red"},
                %{stop: "place-C", route: "Red"}
              ],
              active_period: [{~U[2020-05-06T09:00:00Z], nil}]
            )
          ]
      end

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
                      id: "B1",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B2",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B3",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B4",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          slot_names: [:main_content_zero],
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
                      id: "B1",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B2",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B3",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B4",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          slot_names: [:main_content_one],
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
                      id: "B1",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B2",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B3",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B4",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
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

    test "returns normal sections for branch station for alert with branch terminal headsign", %{
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

      fetch_alerts_fn = fn
        [
          direction_id: :both,
          route_ids: [],
          stop_ids: ["place-kencl"],
          route_types: [:light_rail, :subway]
        ] ->
          [
            # Suspension alert from Kenmore to Saint Mary's Street
            struct(Alert,
              effect: :suspension,
              informed_entities: [
                %{
                  direction_id: nil,
                  facility: nil,
                  route: "Green-C",
                  route_type: 0,
                  stop: "70150"
                },
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
                  stop: "70211"
                },
                %{
                  direction_id: nil,
                  facility: nil,
                  route: "Green-C",
                  route_type: 0,
                  stop: "70212"
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
                  stop: "place-smary"
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
            %NormalSection{
              layout: %Layout{},
              header: %SectionHeader{},
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "Kenmore",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          slot_names: [:main_content_zero],
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
                      id: "Kenmore",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          slot_names: [:main_content_one],
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
                      id: "Kenmore",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
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

    test "returns no data sections for disabled mode", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_routes_fn: fetch_routes_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_vehicles_fn: fetch_vehicles_fn
    } do
      config =
        config
        |> put_primary_departures([
          %Section{query: %Query{params: %Query.Params{stop_ids: ["Boat"]}}},
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-A"], route_ids: ["Orange"]}}
          }
        ])
        |> put_secondary_departures_sections([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-A"], route_ids: ["Orange"]}}
          },
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-A"], route_ids: ["Green"]}}
          }
        ])

      now = ~U[2020-04-06T10:00:00Z]

      expected_departures = [
        %DeparturesWidget{
          screen: config,
          sections: [
            %NoDataSection{route: %{id: "Ferry", type: :ferry}},
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
            }
          ],
          slot_names: [:main_content_zero],
          now: now
        },
        %DeparturesWidget{
          screen: config,
          sections: [
            %NoDataSection{route: %{id: "Ferry", type: :ferry}},
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
            }
          ],
          slot_names: [:main_content_one],
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
            %NoDataSection{route: %{id: "Green", type: :light_rail}}
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

    test "consolidates into DeparturesNoData only when all rotations have no data", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_fn: fetch_routes_fn,
      fetch_vehicles_fn: fetch_vehicles_fn
    } do
      now = ~U[2020-04-06T10:00:00Z]

      instances_partial_data =
        config
        |> put_primary_departures([
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-A"], route_ids: []}}}
        ])
        |> put_secondary_departures_sections([
          %Section{query: %Query{params: %Query.Params{stop_ids: ["nonexist"], route_ids: []}}}
        ])
        |> Dup.Departures.departures_instances(
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_fn,
          fetch_vehicles_fn
        )

      instances_no_data =
        config
        |> put_primary_departures([
          %Section{query: %Query{params: %Query.Params{stop_ids: ["nonexist1"], route_ids: []}}}
        ])
        |> put_secondary_departures_sections([
          %Section{query: %Query{params: %Query.Params{stop_ids: ["nonexist2"], route_ids: []}}}
        ])
        |> Dup.Departures.departures_instances(
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(instances_partial_data, &match?(%DeparturesWidget{}, &1))
      assert Enum.all?(instances_no_data, &match?(%DeparturesNoData{}, &1))
    end
  end

  describe "overnight mode" do
    test "returns normal sections with normal rows and overnight rows for routes in overnight mode",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           fetch_routes_fn: fetch_routes_fn,
           fetch_vehicles_fn: fetch_vehicles_fn
         } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}
          }
        ])
        |> put_secondary_departures_sections([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["bus-A", "bus-B"]}}
          }
        ])

      now = ~U[2020-04-06T10:00:00Z]

      fetch_schedules_fn = fn
        _, nil ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-06T09:00:00Z],
               route: %Route{id: "Bus B"},
               stop: struct(Stop, id: "bus-B")
             }
           ]}

        _, _ ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-07T09:00:00Z],
               route: %Route{id: "Bus B"},
               stop: struct(Stop, id: "bus-B")
             }
           ]}
      end

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
            }
          ],
          slot_names: [:main_content_zero],
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
            }
          ],
          slot_names: [:main_content_one],
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
                      id: "Bus A",
                      route: %Route{id: "Bus A", type: :bus},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: nil,
                  schedule:
                    struct(Schedule,
                      departure_time: ~U[2020-04-07T09:00:00Z],
                      route: %Route{id: "Bus B"},
                      stop: struct(Stop, id: "bus-B")
                    )
                }
              ]
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

    test "returns normal sections with normal rows and overnight rows with nil scheduled times for routes in overnight mode with no scheduled trips tomorrow",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           fetch_routes_fn: fetch_routes_fn,
           fetch_vehicles_fn: fetch_vehicles_fn
         } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}
          }
        ])
        |> put_secondary_departures_sections([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["bus-A", "bus-B"]}}
          }
        ])

      now = ~U[2020-04-06T10:00:00Z]

      fetch_schedules_fn = fn
        _, ^now ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-06T09:00:00Z],
               route: %Route{id: "Bus B"},
               stop: struct(Stop, id: "bus-B")
             }
           ]}

        _, _ ->
          {:ok, []}
      end

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
            }
          ],
          slot_names: [:main_content_zero],
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
            }
          ],
          slot_names: [:main_content_one],
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
                      id: "Bus A",
                      route: %Route{id: "Bus A", type: :bus},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: nil,
                  schedule:
                    struct(Schedule,
                      departure_time: nil,
                      route: %Route{id: "Bus B"},
                      stop: struct(Stop, id: "bus-B")
                    )
                }
              ]
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

    @tag capture_log: true
    test "returns no-data if now is after tomorrow's first schedule",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           fetch_routes_fn: fetch_routes_fn,
           fetch_vehicles_fn: fetch_vehicles_fn
         } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["bus-B"]}}
          }
        ])

      now = ~U[2020-04-06T10:00:00Z]

      fetch_schedules_fn = fn
        _, nil ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-06T09:00:00Z],
               route: %Route{id: "Bus B"},
               stop: struct(Stop, id: "bus-B")
             }
           ]}

        _, _ ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-03-07T09:00:00Z],
               route: %Route{id: "Bus B"},
               stop: struct(Stop, id: "bus-B")
             }
           ]}
      end

      expected_instances = [
        %DeparturesNoData{screen: config, slot_name: :main_content_zero},
        %DeparturesNoData{screen: config, slot_name: :main_content_one},
        %DeparturesNoData{screen: config, slot_name: :main_content_two}
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

      assert Enum.all?(expected_instances, &Enum.member?(actual_instances, &1))
    end

    test "returns no-data if now is before today's last schedule and there are no schedules tomorrow",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           fetch_routes_fn: fetch_routes_fn,
           fetch_vehicles_fn: fetch_vehicles_fn
         } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["bus-B"]}}
          }
        ])

      now = ~U[2020-04-06T08:00:00Z]

      fetch_schedules_fn = fn
        _, nil ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-06T09:00:00Z],
               route: %Route{id: "Bus B"},
               stop: struct(Stop, id: "bus-B")
             }
           ]}

        _, _ ->
          {:ok, []}
      end

      expected_instances = [
        %DeparturesNoData{screen: config, slot_name: :main_content_zero},
        %DeparturesNoData{screen: config, slot_name: :main_content_one},
        %DeparturesNoData{screen: config, slot_name: :main_content_two}
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

      assert Enum.all?(expected_instances, &Enum.member?(actual_instances, &1))
    end

    test "returns OvernightDepartures if all routes in section are overnight",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           fetch_routes_fn: fetch_routes_fn,
           fetch_vehicles_fn: fetch_vehicles_fn
         } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}
          }
        ])
        |> put_secondary_departures_sections([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["bus-B"]}}
          }
        ])

      now = ~U[2020-04-06T10:00:00Z]

      fetch_schedules_fn = fn
        _, nil ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-06T09:00:00Z],
               route: %Route{id: "Bus B"},
               stop: struct(Stop, id: "bus-B")
             }
           ]}

        _, _ ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-07T09:00:00Z],
               route: %Route{id: "Bus B"},
               stop: struct(Stop, id: "bus-B")
             }
           ]}
      end

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
            }
          ],
          slot_names: [:main_content_zero],
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
            }
          ],
          slot_names: [:main_content_one],
          now: now
        },
        %OvernightDepartures{screen: config, routes: [:bus], slot_names: [:main_content_two]}
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

    test "returns OvernightDepartures with no routes if all rotations are overnight",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           fetch_routes_fn: fetch_routes_fn,
           fetch_vehicles_fn: fetch_vehicles_fn
         } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["bus-B", "bus-C"]}}
          }
        ])

      now = ~U[2020-04-06T10:00:00Z]

      fetch_schedules_fn = fn
        _, nil ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-06T09:00:00Z],
               route: %Route{id: "Bus B"},
               stop: struct(Stop, id: "bus-B")
             },
             %Schedule{
               departure_time: ~U[2020-04-06T09:30:00Z],
               route: %Route{id: "Bus C"},
               stop: struct(Stop, id: "bus-C")
             }
           ]}

        _, _ ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-07T09:00:00Z],
               route: %Route{id: "Bus B"},
               stop: struct(Stop, id: "bus-B")
             },
             %Schedule{
               departure_time: ~U[2020-04-07T09:00:00Z],
               route: %Route{id: "Bus C"},
               stop: struct(Stop, id: "bus-C")
             }
           ]}
      end

      expected_departures = [
        %OvernightDepartures{screen: config, routes: [], slot_names: [:main_content_zero]},
        %OvernightDepartures{screen: config, routes: [], slot_names: [:main_content_one]},
        %OvernightDepartures{screen: config, routes: [], slot_names: [:main_content_two]}
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

    test "returns OvernightDepartures for rail sections with active alert and no active vehicles",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_routes_fn: fetch_routes_fn
         } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-overnight"]}}
          }
        ])

      now = ~U[2020-04-06T10:00:00Z]
      stub(@headways, :get_with_route, fn "place-overnight", "Red", ^now -> {5, 8} end)

      fetch_schedules_fn = fn
        _, nil ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-06T09:00:00Z],
               route: %Route{id: "Red"},
               stop: struct(Stop, id: "place-overnight")
             }
           ]}

        _, _ ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-07T09:00:00Z],
               route: %Route{id: "Red"},
               stop: struct(Stop, id: "place-overnight")
             }
           ]}
      end

      fetch_alerts_fn = fn
        [
          direction_id: :both,
          route_ids: [],
          stop_ids: ["place-overnight"],
          route_types: [:light_rail, :subway]
        ] ->
          [
            struct(Alert,
              effect: :suspension,
              informed_entities: [
                %{
                  route: %{id: "Red"},
                  route_type: 0,
                  stop: "place-overnight"
                }
              ],
              active_period: [{~U[2020-04-06T09:00:00Z], nil}]
            )
          ]
      end

      fetch_vehicles_fn = fn _, _ -> [] end

      expected_departures = [
        %OvernightDepartures{screen: config, routes: [], slot_names: [:main_content_zero]},
        %OvernightDepartures{screen: config, routes: [], slot_names: [:main_content_one]},
        %OvernightDepartures{screen: config, routes: [], slot_names: [:main_content_two]}
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

    test "returns primary section Departures if not all routes in secondary section are overnight, but none have upcoming predictions",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           fetch_routes_fn: fetch_routes_fn,
           fetch_vehicles_fn: fetch_vehicles_fn
         } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}
          }
        ])
        |> put_secondary_departures_sections([
          %Section{query: %Query{params: %Query.Params{stop_ids: ["bus-C+D"]}}}
        ])

      now = ~U[2020-04-06T10:00:00Z]

      fetch_schedules_fn = fn
        %{direction_id: :both, route_ids: [], route_type: nil, stop_ids: ["bus-C+D"]},
        ~D[2020-04-07] ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-07T09:00:00Z],
               route: %Route{id: "Bus C"},
               stop: struct(Stop, id: "bus-C+D")
             },
             %Schedule{
               departure_time: ~U[2020-04-07T09:00:00Z],
               route: %Route{id: "Bus D"},
               stop: struct(Stop, id: "bus-C+D")
             }
           ]}

        _, _ ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-06T09:00:00Z],
               route: %Route{id: "Bus C"},
               stop: struct(Stop, id: "bus-C+D")
             },
             %Schedule{
               departure_time: ~U[2020-04-06T09:00:00Z],
               route: %Route{id: "Bus D"},
               stop: struct(Stop, id: "bus-C+D")
             },
             %Schedule{
               departure_time: ~U[2020-04-06T11:01:00Z],
               route: %Route{id: "Bus D"},
               stop: struct(Stop, id: "bus-C+D")
             }
           ]}
      end

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
            }
          ],
          slot_names: [:main_content_zero],
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
            }
          ],
          slot_names: [:main_content_one],
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

    test "returns primary section Departures if routes in secondary section have no predictions for today or schedules for tomorrow",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           fetch_routes_fn: fetch_routes_fn,
           fetch_vehicles_fn: fetch_vehicles_fn
         } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}
          }
        ])
        |> put_secondary_departures_sections([
          %Section{query: %Query{params: %Query.Params{stop_ids: ["bus-C"]}}}
        ])

      now = ~U[2020-04-06T10:00:00Z]

      fetch_schedules_fn = fn
        %{direction_id: :both, route_ids: [], route_type: nil, stop_ids: ["bus-C"]},
        ~D[2020-04-07] ->
          {:ok, []}

        _, _ ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-06T09:00:00Z],
               route: %Route{id: "Bus C"},
               stop: struct(Stop, id: "bus-C")
             },
             %Schedule{
               departure_time: ~U[2020-04-06T11:00:00Z],
               route: %Route{id: "Bus C"},
               stop: struct(Stop, id: "bus-C")
             }
           ]}
      end

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
            }
          ],
          slot_names: [:main_content_zero],
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
            }
          ],
          slot_names: [:main_content_one],
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
  end

  describe "departures_instances/4 alert handling" do
    test "returns no departures for a section when alerts indicate that all routes are expected to be closed",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_routes_fn: fetch_routes_fn
         } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{
              params: %Query.Params{stop_ids: ["place-closed"], route_ids: ["Red"]}
            }
          },
          %Section{
            query: %Query{
              params: %Query.Params{stop_ids: ["bus-A", "bus-B"], route_ids: ["Bus A"]}
            }
          }
        ])

      now = ~U[2020-04-06T18:00:00Z]

      fetch_schedules_fn = fn
        _, ~D[2020-04-07] ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-07T09:00:00Z],
               route: %Route{id: "Red"},
               stop: struct(Stop, id: "place-closed")
             }
           ]}

        _, ^now ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-06T09:00:00Z],
               route: %Route{id: "Red"},
               stop: struct(Stop, id: "place-closed")
             },
             %Schedule{
               departure_time: ~U[2020-04-07T03:00:00Z],
               route: %Route{id: "Red"},
               stop: struct(Stop, id: "place-closed")
             }
           ]}
      end

      fetch_alerts_fn = fn
        [
          direction_id: :both,
          route_ids: ["Red"],
          stop_ids: ["place-closed"],
          route_types: [:light_rail, :subway]
        ] ->
          [
            struct(Alert,
              effect: :suspension,
              informed_entities: [
                %{
                  route: "Red",
                  route_type: 0,
                  stop: "place-closed",
                  direction_id: nil
                }
              ],
              active_period: [{~U[2020-04-06T09:00:00Z], nil}]
            )
          ]

        _ ->
          []
      end

      fetch_vehicles_fn = fn _, _ -> [] end

      expected_departures = [
        %DeparturesWidget{
          screen: config,
          sections: [
            %NormalSection{
              layout: %Layout{},
              header: %SectionHeader{},
              rows: []
            },
            %NormalSection{
              layout: %Layout{},
              header: %SectionHeader{},
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "Bus A",
                      route: %Route{id: "Bus A", type: :bus},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          now: now,
          slot_names: [:main_content_reduced_two]
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

      assert(Enum.all?(expected_departures, &Enum.member?(actual_instances, &1)))
    end

    test "returns NoDataSection when alerts do not cover all directions for which we are missing departures",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_routes_fn: fetch_routes_fn
         } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{
              params: %Query.Params{stop_ids: ["place-closed"], route_ids: ["Red"]}
            }
          },
          %Section{
            query: %Query{
              params: %Query.Params{stop_ids: ["bus-A", "bus-B"], route_ids: ["Bus A"]}
            }
          }
        ])

      now = ~U[2020-04-06T18:00:00Z]

      fetch_schedules_fn = fn
        _, ~D[2020-04-07] ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-07T09:00:00Z],
               route: %Route{id: "Red"},
               stop: struct(Stop, id: "place-closed")
             }
           ]}

        _, ^now ->
          {:ok,
           [
             %Schedule{
               departure_time: ~U[2020-04-06T09:00:00Z],
               route: %Route{id: "Red"},
               stop: struct(Stop, id: "place-closed")
             },
             %Schedule{
               departure_time: ~U[2020-04-07T03:00:00Z],
               route: %Route{id: "Red"},
               stop: struct(Stop, id: "place-closed")
             }
           ]}
      end

      fetch_alerts_fn = fn
        [
          direction_id: :both,
          route_ids: ["Red"],
          stop_ids: ["place-closed"],
          route_types: [:light_rail, :subway]
        ] ->
          [
            struct(Alert,
              effect: :suspension,
              informed_entities: [
                %{
                  route: %{id: "Red"},
                  route_type: 0,
                  stop: "place-closed",
                  direction_id: 0
                }
              ],
              active_period: [{~U[2020-04-06T09:00:00Z], nil}]
            )
          ]

        _ ->
          []
      end

      fetch_vehicles_fn = fn _, _ -> [] end

      expected_departures = [
        %DeparturesWidget{
          screen: config,
          sections: [
            %NoDataSection{route: %{id: "Red", type: :subway}},
            %NormalSection{
              layout: %Layout{},
              header: %SectionHeader{},
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "Bus A",
                      route: %Route{id: "Bus A", type: :bus},
                      stop: struct(Stop),
                      trip: struct(Trip)
                    ),
                  schedule: nil
                }
              ]
            }
          ],
          now: now,
          slot_names: [:main_content_zero]
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

      assert(Enum.all?(expected_departures, &Enum.member?(actual_instances, &1)))
    end
  end
end
