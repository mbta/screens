defmodule Screens.V2.CandidateGenerator.Dup.DeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{Departures, Header}
  alias Screens.Config.V2.Departures.{Headway, Query, Section}
  alias Screens.Config.V2.Dup, as: DupConfig
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V2.Departure
  alias Screens.V2.CandidateGenerator.Dup
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.{DeparturesNoData, OvernightDepartures}

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
        }
      },
      vendor: :outfront,
      device_id: "TEST",
      name: "TEST",
      app_id: :dup_v2
    }

    fetch_section_departures_fn = fn
      %Section{query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}} ->
        {:ok,
         [
           %Departure{
             prediction:
               struct(Prediction, id: "A", route: %Route{id: "Test"}, stop: struct(Stop))
           }
         ]}

      %Section{query: %Query{params: %Query.Params{stop_ids: ["place-B"]}}} ->
        {:ok,
         [
           %Departure{
             prediction:
               struct(Prediction, id: "B1", route: %Route{id: "Test"}, stop: struct(Stop))
           },
           %Departure{
             prediction:
               struct(Prediction, id: "B2", route: %Route{id: "Test"}, stop: struct(Stop))
           },
           %Departure{
             prediction:
               struct(Prediction, id: "B3", route: %Route{id: "Test"}, stop: struct(Stop))
           },
           %Departure{
             prediction:
               struct(Prediction, id: "B4", route: %Route{id: "Test"}, stop: struct(Stop))
           },
           %Departure{
             prediction:
               struct(Prediction, id: "B5", route: %Route{id: "Test"}, stop: struct(Stop))
           }
         ]}

      %Section{query: %Query{params: %Query.Params{stop_ids: ["place-C"]}}} ->
        {:ok,
         [
           %Departure{
             prediction:
               struct(Prediction, id: "C", route: %Route{id: "Test"}, stop: struct(Stop))
           }
         ]}

      %Section{query: %Query{params: %Query.Params{stop_ids: ["place-D"]}}} ->
        {:ok,
         [
           %Departure{
             prediction:
               struct(Prediction, id: "D", route: %Route{id: "Test"}, stop: struct(Stop))
           }
         ]}

      %Section{query: %Query{params: %Query.Params{stop_ids: ["place-F"]}}} ->
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

      %Section{query: %Query{params: %Query.Params{stop_ids: ["place-kencl"]}}} ->
        {:ok,
         [
           %Departure{
             prediction:
               struct(Prediction, id: "Kenmore", route: %Route{id: "Test"}, stop: struct(Stop))
           }
         ]}

      %Section{query: %Query{params: %Query.Params{stop_ids: ["bus-A", "bus-B"]}}} ->
        {:ok,
         [
           %Departure{
             prediction:
               struct(Prediction,
                 id: "Bus A",
                 route: %Route{id: "Bus A", type: :bus},
                 stop: struct(Stop)
               )
           }
         ]}

      _ ->
        {:ok, []}
    end

    fetch_alerts_fn = fn
      _ -> []
    end

    fetch_schedules_fn = fn
      _, _ ->
        []
    end

    create_station_with_routes_map_fn = fn
      "Boat" -> [%{id: "Ferry", type: :ferry}]
      "place-A" -> [%{id: "Orange", type: :subway}, %{id: "Green", type: :light_rail}]
      "bus-A" -> [%{id: "Bus A", type: :bus}]
      "bus-B" -> [%{id: "Bus B", type: :bus}]
      _ -> [%{type: :test}]
    end

    %{
      config: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      create_station_with_routes_map_fn: create_station_with_routes_map_fn
    }
  end

  describe "departures_instances/4" do
    test "returns primary and secondary departures", %{
      config: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      create_station_with_routes_map_fn: create_station_with_routes_map_fn
    } do
      config =
        config
        |> put_primary_departures([
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}, filter: nil},
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-B"]}}, filter: nil}
        ])
        |> put_secondary_departures_sections([
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-C"]}}, filter: nil},
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-D"]}}, filter: nil}
        ])

      now = ~U[2020-04-06T10:00:00Z]

      expected_departures = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "A", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                }
              ]
            },
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B1", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B2", route: %Route{id: "Test"}, stop: struct(Stop)),
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "A", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                }
              ]
            },
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B1", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B2", route: %Route{id: "Test"}, stop: struct(Stop)),
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "C", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                }
              ]
            },
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "D", route: %Route{id: "Test"}, stop: struct(Stop)),
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
          fetch_section_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          create_station_with_routes_map_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns only primary departures if secondary is missing", %{
      config: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      create_station_with_routes_map_fn: create_station_with_routes_map_fn
    } do
      config =
        put_primary_departures(config, [
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}, filter: nil},
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-B"]}}, filter: nil}
        ])

      now = ~U[2020-04-06T10:00:00Z]

      expected_departures = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "A", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                }
              ]
            },
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B1", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B2", route: %Route{id: "Test"}, stop: struct(Stop)),
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "A", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                }
              ]
            },
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B1", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B2", route: %Route{id: "Test"}, stop: struct(Stop)),
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "A", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                }
              ]
            },
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B1", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B2", route: %Route{id: "Test"}, stop: struct(Stop)),
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
          fetch_section_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          create_station_with_routes_map_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns only bidirectional departures if configured for that", %{
      config: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      create_station_with_routes_map_fn: create_station_with_routes_map_fn
    } do
      config =
        put_primary_departures(config, [
          %Section{
            bidirectional: true,
            query: %Query{params: %Query.Params{stop_ids: ["place-F"]}},
            filter: nil
          },
          %Section{query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}, filter: nil}
        ])

      now = ~U[2020-04-06T10:00:00Z]

      expected_departures = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "A", stop: struct(Stop), route: %Route{id: "Test"}),
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "A", stop: struct(Stop), route: %Route{id: "Test"}),
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "A", stop: struct(Stop), route: %Route{id: "Test"}),
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
          fetch_section_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          create_station_with_routes_map_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns 4 departures if only one section", %{
      config: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      create_station_with_routes_map_fn: create_station_with_routes_map_fn
    } do
      config =
        put_primary_departures(config, [
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-B"]}},
            filter: nil,
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B1", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B2", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B3", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B4", route: %Route{id: "Test"}, stop: struct(Stop)),
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B1", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B2", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B3", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B4", route: %Route{id: "Test"}, stop: struct(Stop)),
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B1", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B2", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B3", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B4", route: %Route{id: "Test"}, stop: struct(Stop)),
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
          fetch_section_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          create_station_with_routes_map_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns headway sections for temporary terminal", %{
      config: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      create_station_with_routes_map_fn: create_station_with_routes_map_fn
    } do
      config =
        put_primary_departures(config, [
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-B"]}},
            filter: nil,
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
              headsign: "Test"
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
              headsign: "Test"
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
              headsign: "Test"
            }
          ],
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_section_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          create_station_with_routes_map_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns normal sections for upcoming alert", %{
      config: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      create_station_with_routes_map_fn: create_station_with_routes_map_fn
    } do
      config =
        put_primary_departures(config, [
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-B"]}},
            filter: nil,
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B1", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B2", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B3", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B4", route: %Route{id: "Test"}, stop: struct(Stop)),
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B1", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B2", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B3", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B4", route: %Route{id: "Test"}, stop: struct(Stop)),
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B1", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B2", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "B3", route: %Route{id: "Test"}, stop: struct(Stop)),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "B4",
                      route: %Route{id: "Test"},
                      stop: struct(Stop),
                      stop: struct(Stop)
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
          fetch_section_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          create_station_with_routes_map_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns normal sections for branch station for alert with branch terminal headsign", %{
      config: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      create_station_with_routes_map_fn: create_station_with_routes_map_fn
    } do
      config =
        put_primary_departures(config, [
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-kencl"]}},
            filter: nil,
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "Kenmore",
                      route: %Route{id: "Test"},
                      stop: struct(Stop)
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "Kenmore",
                      route: %Route{id: "Test"},
                      stop: struct(Stop)
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "Kenmore",
                      route: %Route{id: "Test"},
                      stop: struct(Stop)
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
          fetch_section_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          create_station_with_routes_map_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns headway sections for branch station for alert with trunk headsign", %{
      config: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      create_station_with_routes_map_fn: create_station_with_routes_map_fn
    } do
      config =
        put_primary_departures(config, [
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-kencl"]}},
            filter: nil,
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
                  stop: "70152"
                },
                %{
                  direction_id: nil,
                  facility: nil,
                  route: "Green-C",
                  route_type: 0,
                  stop: "70153"
                },
                %{
                  direction_id: nil,
                  facility: nil,
                  route: "Green-C",
                  route_type: 0,
                  stop: "place-hymnl"
                },
                %{
                  direction_id: nil,
                  facility: nil,
                  route: "Green-C",
                  route_type: 0,
                  stop: "place-kencl"
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
              route: "Green",
              time_range: {7, 13},
              headsign: "Park Street"
            }
          ],
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :headway_section,
              route: "Green",
              time_range: {7, 13},
              headsign: "Park Street"
            }
          ],
          slot_names: [:main_content_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :headway_section,
              route: "Green",
              time_range: {7, 13},
              headsign: "Park Street"
            }
          ],
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_section_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          create_station_with_routes_map_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns no data sections for disabled mode", %{
      config: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      create_station_with_routes_map_fn: create_station_with_routes_map_fn,
      fetch_schedules_fn: fetch_schedules_fn
    } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["Boat"]}},
            filter: nil,
            headway: %Headway{headway_id: "ferry"}
          },
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-A"], route_ids: ["Orange"]}},
            filter: nil
          }
        ])
        |> put_secondary_departures_sections([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-A"], route_ids: ["Orange"]}},
            filter: nil
          },
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-A"], route_ids: ["Green"]}},
            filter: nil
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "A", route: %Route{id: "Test"}, stop: struct(Stop)),
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "A", route: %Route{id: "Test"}, stop: struct(Stop)),
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "A", route: %Route{id: "Test"}, stop: struct(Stop)),
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
          fetch_section_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          create_station_with_routes_map_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns DeparturesNoData if all sections have no data", %{
      config: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn,
      fetch_schedules_fn: fetch_schedules_fn,
      create_station_with_routes_map_fn: create_station_with_routes_map_fn
    } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-E"], route_ids: []}},
            filter: nil
          }
        ])
        |> put_secondary_departures_sections([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["Boat"]}},
            filter: nil,
            headway: %Headway{headway_id: "ferry"}
          },
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-A"], route_ids: ["Green"]}},
            filter: nil
          }
        ])

      now = ~U[2020-04-06T10:00:00Z]

      expected_departures = [
        %DeparturesNoData{
          screen: config,
          show_alternatives?: nil,
          slot_name: :main_content_zero
        },
        %DeparturesNoData{
          screen: config,
          show_alternatives?: nil,
          slot_name: :main_content_one
        },
        %DeparturesNoData{
          screen: config,
          show_alternatives?: nil,
          slot_name: :main_content_two
        }
      ]

      actual_instances =
        Dup.Departures.departures_instances(
          config,
          now,
          fetch_section_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          create_station_with_routes_map_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end
  end

  describe "overnight mode for bus" do
    test "returns normal sections with normal rows and overnight rows for routes in overnight mode",
         %{
           config: config,
           fetch_section_departures_fn: fetch_section_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           create_station_with_routes_map_fn: create_station_with_routes_map_fn
         } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-A"]}},
            filter: nil
          }
        ])
        |> put_secondary_departures_sections([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["bus-A", "bus-B"]}},
            filter: nil
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "A", route: %Route{id: "Test"}, stop: struct(Stop)),
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "A", route: %Route{id: "Test"}, stop: struct(Stop)),
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction,
                      id: "Bus A",
                      route: %Route{id: "Bus A", type: :bus},
                      stop: struct(Stop)
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
          fetch_section_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          create_station_with_routes_map_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns OvernightDepartures if all routes in section are overnight",
         %{
           config: config,
           fetch_section_departures_fn: fetch_section_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           create_station_with_routes_map_fn: create_station_with_routes_map_fn
         } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["place-A"]}},
            filter: nil
          }
        ])
        |> put_secondary_departures_sections([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["bus-B"]}},
            filter: nil
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "A", route: %Route{id: "Test"}, stop: struct(Stop)),
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
              rows: [
                %Screens.V2.Departure{
                  prediction:
                    struct(Prediction, id: "A", route: %Route{id: "Test"}, stop: struct(Stop)),
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
          fetch_section_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          create_station_with_routes_map_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns OvernightDepartures with no routes if all rotations are overnight",
         %{
           config: config,
           fetch_section_departures_fn: fetch_section_departures_fn,
           fetch_alerts_fn: fetch_alerts_fn,
           create_station_with_routes_map_fn: create_station_with_routes_map_fn
         } do
      config =
        config
        |> put_primary_departures([
          %Section{
            query: %Query{params: %Query.Params{stop_ids: ["bus-B"]}},
            filter: nil
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
          fetch_section_departures_fn,
          fetch_alerts_fn,
          fetch_schedules_fn,
          create_station_with_routes_map_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end
  end
end
