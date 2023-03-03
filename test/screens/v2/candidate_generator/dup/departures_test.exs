defmodule Screens.V2.CandidateGenerator.Dup.DeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{Departures, Header}
  alias Screens.Config.V2.Departures.{Headway, Query, Section}
  alias Screens.Config.V2.Dup, as: DupConfig
  alias Screens.Predictions.Prediction
  alias Screens.V2.Departure
  alias Screens.V2.CandidateGenerator.Dup
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget

  setup do
    config_primary_and_secondary = %Screen{
      app_params: %DupConfig{
        header: %Header.CurrentStopId{stop_id: "place-gover"},
        primary_departures: %Departures{
          sections: [
            %Section{query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}, filter: nil},
            %Section{query: %Query{params: %Query.Params{stop_ids: ["place-B"]}}, filter: nil}
          ]
        },
        secondary_departures: %Departures{
          sections: [
            %Section{query: %Query{params: %Query.Params{stop_ids: ["place-C"]}}, filter: nil},
            %Section{query: %Query{params: %Query.Params{stop_ids: ["place-D"]}}, filter: nil}
          ]
        }
      },
      vendor: :outfront,
      device_id: "TEST",
      name: "TEST",
      app_id: :dup_v2
    }

    config_only_primary = %Screen{
      app_params: %DupConfig{
        header: %Header.CurrentStopId{stop_id: "place-gover"},
        primary_departures: %Departures{
          sections: [
            %Section{query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}, filter: nil},
            %Section{query: %Query{params: %Query.Params{stop_ids: ["place-B"]}}, filter: nil}
          ]
        },
        secondary_departures: %Departures{sections: []}
      },
      vendor: :outfront,
      device_id: "TEST",
      name: "TEST",
      app_id: :dup_v2
    }

    config_one_section = %Screen{
      app_params: %DupConfig{
        header: %Header.CurrentStopId{stop_id: "place-gover"},
        primary_departures: %Departures{
          sections: [
            %Section{
              query: %Query{params: %Query.Params{stop_ids: ["place-B"]}},
              filter: nil,
              headway: %Headway{headway_id: "red_trunk"}
            }
          ]
        },
        secondary_departures: %Departures{sections: []}
      },
      vendor: :outfront,
      device_id: "TEST",
      name: "TEST",
      app_id: :dup_v2
    }

    config_branch_station = %Screen{
      app_params: %DupConfig{
        header: %Header.CurrentStopId{stop_id: "place-kencl"},
        primary_departures: %Departures{
          sections: [
            %Section{
              query: %Query{params: %Query.Params{stop_ids: ["place-kencl"]}},
              filter: nil,
              headway: %Headway{headway_id: "green_trunk"}
            }
          ]
        },
        secondary_departures: %Departures{sections: []}
      },
      vendor: :outfront,
      device_id: "TEST",
      name: "TEST",
      app_id: :dup_v2
    }

    fetch_section_departures_fn = fn
      %Section{query: %Query{params: %Query.Params{stop_ids: ["place-A"]}}} ->
        {:ok, [%Departure{prediction: %Prediction{id: "A"}}]}

      %Section{query: %Query{params: %Query.Params{stop_ids: ["place-B"]}}} ->
        {:ok,
         [
           %Departure{prediction: %Prediction{id: "B1"}},
           %Departure{prediction: %Prediction{id: "B2"}},
           %Departure{prediction: %Prediction{id: "B3"}},
           %Departure{prediction: %Prediction{id: "B4"}},
           %Departure{prediction: %Prediction{id: "B5"}}
         ]}

      %Section{query: %Query{params: %Query.Params{stop_ids: ["place-C"]}}} ->
        {:ok, [%Departure{prediction: %Prediction{id: "C"}}]}

      %Section{query: %Query{params: %Query.Params{stop_ids: ["place-D"]}}} ->
        {:ok, [%Departure{prediction: %Prediction{id: "D"}}]}

      %Section{query: %Query{params: %Query.Params{stop_ids: ["place-kencl"]}}} ->
        {:ok, [%Departure{prediction: %Prediction{id: "Kenmore"}}]}
    end

    fetch_alerts_fn = fn
      _ -> []
    end

    %{
      config_primary_and_secondary: config_primary_and_secondary,
      config_only_primary: config_only_primary,
      config_one_section: config_one_section,
      config_branch_station: config_branch_station,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn
    }
  end

  describe "departures_instances/4" do
    test "returns primary and secondary departures", %{
      config_primary_and_secondary: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn
    } do
      now = ~U[2020-04-06T10:00:00Z]

      expected_departures = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "A"),
                  schedule: nil
                }
              ]
            },
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B1"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B2"),
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
                  prediction: struct(Prediction, id: "A"),
                  schedule: nil
                }
              ]
            },
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B1"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B2"),
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
                  prediction: struct(Prediction, id: "C"),
                  schedule: nil
                }
              ]
            },
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "D"),
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
          fetch_alerts_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns only primary departures if secondary is missing", %{
      config_only_primary: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn
    } do
      now = ~U[2020-04-06T10:00:00Z]

      expected_departures = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "A"),
                  schedule: nil
                }
              ]
            },
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B1"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B2"),
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
                  prediction: struct(Prediction, id: "A"),
                  schedule: nil
                }
              ]
            },
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B1"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B2"),
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
                  prediction: struct(Prediction, id: "A"),
                  schedule: nil
                }
              ]
            },
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B1"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B2"),
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
          fetch_alerts_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns 4 departures if only one section", %{
      config_one_section: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_alerts_fn: fetch_alerts_fn
    } do
      now = ~U[2020-04-06T10:00:00Z]

      expected_departures = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{
              type: :normal_section,
              rows: [
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B1"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B2"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B3"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B4"),
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
                  prediction: struct(Prediction, id: "B1"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B2"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B3"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B4"),
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
                  prediction: struct(Prediction, id: "B1"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B2"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B3"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B4"),
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
          fetch_alerts_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns headway sections for temporary terminal", %{
      config_one_section: config,
      fetch_section_departures_fn: fetch_section_departures_fn
    } do
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
              pill: :red,
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
              pill: :red,
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
              pill: :red,
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
          fetch_alerts_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns normal sections for upcoming alert", %{
      config_one_section: config,
      fetch_section_departures_fn: fetch_section_departures_fn
    } do
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
                  prediction: struct(Prediction, id: "B1"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B2"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B3"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B4"),
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
                  prediction: struct(Prediction, id: "B1"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B2"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B3"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B4"),
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
                  prediction: struct(Prediction, id: "B1"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B2"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B3"),
                  schedule: nil
                },
                %Screens.V2.Departure{
                  prediction: struct(Prediction, id: "B4"),
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
          fetch_alerts_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns normal sections for branch station for alert with branch terminal headsign", %{
      config_branch_station: config,
      fetch_section_departures_fn: fetch_section_departures_fn
    } do
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
                  prediction: struct(Prediction, id: "Kenmore"),
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
                  prediction: struct(Prediction, id: "Kenmore"),
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
                  prediction: struct(Prediction, id: "Kenmore"),
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
          fetch_alerts_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns headway sections for branch station for alert with trunk headsign", %{
      config_branch_station: config,
      fetch_section_departures_fn: fetch_section_departures_fn
    } do
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
              pill: :"green-c",
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
              pill: :"green-c",
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
              pill: :"green-c",
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
          fetch_alerts_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end
  end
end
