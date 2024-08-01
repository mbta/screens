defmodule Screens.V2.CandidateGenerator.Dup.DeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.{Alerts, Departures, Header}
  alias ScreensConfig.V2.Departures.Header, as: SectionHeader
  alias ScreensConfig.V2.Departures.{Headway, Layout, Query, Section}
  alias ScreensConfig.V2.Dup, as: DupConfig
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.Vehicles.Vehicle
  alias Screens.V2.Departure
  alias Screens.V2.CandidateGenerator.Dup
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.OvernightDepartures

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
    config = %Screen{
      app_params: %DupConfig{
        header: %Header.CurrentStopId{stop_id: "place-test"},
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

    fetch_routes_serving_stop_fn = fn
      "Boat" -> {:ok, [%{id: "Ferry", type: :ferry}]}
      "place-A" -> {:ok, [%{id: "Orange", type: :subway}, %{id: "Green", type: :light_rail}]}
      "bus-A" -> {:ok, [%{id: "Bus A", type: :bus}]}
      "bus-B" -> {:ok, [%{id: "Bus B", type: :bus}]}
      "place-overnight" -> {:ok, [%{id: "Red", type: :subway}]}
      _ -> {:ok, [%{id: "test", type: :test}]}
    end

    %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
      fetch_vehicles_fn: fetch_vehicles_fn
    }
  end

  describe "departures_instances/4" do
    test "returns primary and secondary departures", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
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
          section_data: [
            %{
              type: :normal_section,
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
            %{
              type: :normal_section,
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
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
            %{
              type: :normal_section,
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
          slot_names: [:main_content_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
            %{
              type: :normal_section,
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
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns only primary departures if secondary is missing", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
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
          section_data: [
            %{
              type: :normal_section,
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
            %{
              type: :normal_section,
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
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
            %{
              type: :normal_section,
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
          slot_names: [:main_content_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
            %{
              type: :normal_section,
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
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns only bidirectional departures if configured for that", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
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
          section_data: [
            %{
              type: :normal_section,
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
            %{
              type: :normal_section,
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
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
            %{
              type: :normal_section,
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
          slot_names: [:main_content_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
            %{
              type: :normal_section,
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
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns one row for bidirectional departures if only one departure exists", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
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
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns 4 departures if only one section", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
      fetch_vehicles_fn: fetch_vehicles_fn
    } do
      config =
        put_primary_departures(config, [
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-B"]}},
            headway: %Headway{headway_id: "red_trunk"}
          }
        ])

      now = ~U[2020-04-06T10:00:00Z]

      expected_departures = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns headway sections for temporary terminal", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
      fetch_vehicles_fn: fetch_vehicles_fn
    } do
      config =
        put_primary_departures(config, [
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-B"]}},
            headway: %Headway{headway_id: "red_trunk"}
          }
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
                %{stop: "place-B", route: "Red"}
              ],
              active_period: [{~U[2020-04-06T09:00:00Z], nil}]
            )
          ]
      end

      expected_departures = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :headway_section,
              route: "Red",
              time_range: {12, 16},
              headsign: "Test A"
            }
          ],
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :headway_section,
              route: "Red",
              time_range: {12, 16},
              headsign: "Test A"
            }
          ],
          slot_names: [:main_content_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :headway_section,
              route: "Red",
              time_range: {12, 16},
              headsign: "Test A"
            }
          ],
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns normal sections for upcoming alert", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
      fetch_vehicles_fn: fetch_vehicles_fn
    } do
      config =
        put_primary_departures(config, [
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-B"]}},
            headway: %Headway{headway_id: "red_trunk"}
          }
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
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns normal sections for branch station for alert with branch terminal headsign", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
      fetch_vehicles_fn: fetch_vehicles_fn
    } do
      config =
        put_primary_departures(config, [
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-kencl"]}},
            headway: %Headway{headway_id: "green_trunk"}
          }
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
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns headway sections for branch station for alert with trunk headsign", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
      fetch_vehicles_fn: fetch_vehicles_fn
    } do
      config =
        put_primary_departures(config, [
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-kencl"]}},
            headway: %Headway{headway_id: "green_trunk"}
          }
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
          section_data: [
            %{
              type: :headway_section,
              route: "Green-C",
              time_range: {7, 13},
              headsign: "Westbound"
            }
          ],
          slot_names: [:main_content_reduced_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :headway_section,
              route: "Green-C",
              time_range: {7, 13},
              headsign: "Westbound"
            }
          ],
          slot_names: [:main_content_reduced_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :headway_section,
              route: "Green-C",
              time_range: {7, 13},
              headsign: "Westbound"
            }
          ],
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
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns no data sections for disabled mode", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_vehicles_fn: fetch_vehicles_fn
    } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["Boat"]}},
            headway: %Headway{headway_id: "ferry"}
          },
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
          section_data: [
            %{
              type: :no_data_section,
              route: %{id: "Ferry", type: :ferry}
            },
            %{
              type: :normal_section,
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
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :no_data_section,
              route: %{id: "Ferry", type: :ferry}
            },
            %{
              type: :normal_section,
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
          slot_names: [:main_content_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
            %{
              type: :no_data_section,
              route: %{id: "Green", type: :light_rail}
            }
          ],
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns empty departures list if sections have no departures", %{
      config: config,
      fetch_departures_fn: fetch_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
      fetch_vehicles_fn: fetch_vehicles_fn
    } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-E"], route_ids: []}}
          }
        ])
        |> put_secondary_departures_sections([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["Boat"]}},
            headway: %Headway{headway_id: "ferry"}
          },
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-A"], route_ids: ["Green"]}}
          }
        ])

      now = ~U[2020-04-06T10:00:00Z]

      expected_departures = []

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end
  end

  describe "overnight mode" do
    test "returns normal sections with normal rows and overnight rows for routes in overnight mode",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
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
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns normal sections with normal rows and overnight rows with nil scheduled times for routes in overnight mode with no scheduled trips tomorrow",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
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
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    @tag capture_log: true
    test "returns empty departures if now is after tomorrow's first schedule",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
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

      expected_departures = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{layout: %Layout{}, header: %SectionHeader{}, rows: [], type: :normal_section}
          ],
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{layout: %Layout{}, header: %SectionHeader{}, rows: [], type: :normal_section}
          ],
          slot_names: [:main_content_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{layout: %Layout{}, header: %SectionHeader{}, rows: [], type: :normal_section}
          ],
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns empty departures if now is before today's last schedule and there are no schedules tomorrow",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
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

      expected_departures = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{layout: %Layout{}, header: %SectionHeader{}, rows: [], type: :normal_section}
          ],
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{layout: %Layout{}, header: %SectionHeader{}, rows: [], type: :normal_section}
          ],
          slot_names: [:main_content_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{layout: %Layout{}, header: %SectionHeader{}, rows: [], type: :normal_section}
          ],
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns OvernightDepartures if all routes in section are overnight",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
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
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
          slot_names: [:main_content_one]
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
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns OvernightDepartures with no routes if all rotations are overnight",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn,
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
               departure_time: ~U[2020-04-07T09:00:00Z],
               route: %Route{id: "Bus B"},
               stop: struct(Stop, id: "bus-B")
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
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns OvernightDepartures for rail sections with active alert and no active vehicles",
         %{
           config: config,
           fetch_departures_fn: fetch_departures_fn,
           fetch_routes_serving_stop_fn: fetch_routes_serving_stop_fn
         } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-overnight"]}}
          }
        ])

      now = ~U[2020-04-06T10:00:00Z]

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
          fetch_routes_serving_stop_fn,
          fetch_vehicles_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end
  end
end
