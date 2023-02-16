defmodule Screens.V2.CandidateGenerator.DupTest do
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
  alias Screens.V2.WidgetInstance.NormalHeader

  setup do
    config_primary_and_secondary = %Screen{
      app_params: %DupConfig{
        header: %Header.CurrentStopId{stop_id: "place-gover"},
        primary_departures: %Departures{
          sections: [
            %Section{query: %Query{params: %Query.Params{stop_ids: ["stop A"]}}, filter: nil},
            %Section{query: %Query{params: %Query.Params{stop_ids: ["stop B"]}}, filter: nil}
          ]
        },
        secondary_departures: %Departures{
          sections: [
            %Section{query: %Query{params: %Query.Params{stop_ids: ["stop C"]}}, filter: nil},
            %Section{query: %Query{params: %Query.Params{stop_ids: ["stop D"]}}, filter: nil}
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
            %Section{query: %Query{params: %Query.Params{stop_ids: ["stop A"]}}, filter: nil},
            %Section{query: %Query{params: %Query.Params{stop_ids: ["stop B"]}}, filter: nil}
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
              query: %Query{params: %Query.Params{stop_ids: ["stop B"]}},
              filter: nil,
              headway: %Headway{headway_id: "red_trunk", pill: :red}
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
      %Section{query: %Query{params: %Query.Params{stop_ids: ["stop A"]}}} ->
        {:ok, [%Departure{prediction: %Prediction{id: "A"}}]}

      %Section{query: %Query{params: %Query.Params{stop_ids: ["stop B"]}}} ->
        {:ok,
         [
           %Departure{prediction: %Prediction{id: "B1"}},
           %Departure{prediction: %Prediction{id: "B2"}},
           %Departure{prediction: %Prediction{id: "B3"}},
           %Departure{prediction: %Prediction{id: "B4"}},
           %Departure{prediction: %Prediction{id: "B5"}}
         ]}

      %Section{query: %Query{params: %Query.Params{stop_ids: ["stop C"]}}} ->
        {:ok, [%Departure{prediction: %Prediction{id: "C"}}]}

      %Section{query: %Query{params: %Query.Params{stop_ids: ["stop D"]}}} ->
        {:ok, [%Departure{prediction: %Prediction{id: "D"}}]}
    end

    fetch_alerts_or_empty_list_fn = fn
      _ -> []
    end

    %{
      config_primary_and_secondary: config_primary_and_secondary,
      config_only_primary: config_only_primary,
      config_one_section: config_one_section,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_alerts_or_empty_list_fn: fetch_alerts_or_empty_list_fn
    }
  end

  describe "screen_template/0" do
    test "returns template" do
      assert {:screen,
              %{
                screen_normal: [
                  {:rotation_zero,
                   %{
                     rotation_normal_zero: [
                       :header_zero,
                       {:body_zero,
                        %{
                          body_normal_zero: [:main_content_zero],
                          body_split_zero: [:main_content_reduced_zero, :bottom_pane_zero]
                        }}
                     ],
                     rotation_takeover_zero: [:full_rotation_zero]
                   }},
                  {:rotation_one,
                   %{
                     rotation_normal_one: [
                       :header_one,
                       {:body_one,
                        %{
                          body_normal_one: [:main_content_one],
                          body_split_one: [:main_content_reduced_one, :bottom_pane_one]
                        }}
                     ],
                     rotation_takeover_one: [:full_rotation_one]
                   }},
                  {:rotation_two,
                   %{
                     rotation_normal_two: [
                       :header_two,
                       {:body_two,
                        %{
                          body_normal_two: [:main_content_two],
                          body_split_two: [:main_content_reduced_two, :bottom_pane_two]
                        }}
                     ],
                     rotation_takeover_two: [:full_rotation_two]
                   }}
                ]
              }} == Dup.screen_template()
    end
  end

  describe "candidate_instances/4" do
    test "returns expected header and departures", %{
      config_primary_and_secondary: config,
      fetch_alerts_or_empty_list_fn: fetch_alerts_or_empty_list_fn
    } do
      now = ~U[2020-04-06T10:00:00Z]
      fetch_stop_fn = fn "place-gover" -> "Government Center" end

      fetch_section_departures_fn = fn
        %Section{query: %Query{params: %Query.Params{stop_ids: ["stop A"]}}} -> {:ok, []}
        %Section{query: %Query{params: %Query.Params{stop_ids: ["stop B"]}}} -> {:ok, []}
        %Section{query: %Query{params: %Query.Params{stop_ids: ["stop C"]}}} -> {:ok, []}
        %Section{query: %Query{params: %Query.Params{stop_ids: ["stop D"]}}} -> {:ok, []}
      end

      expected_headers =
        List.duplicate(
          %NormalHeader{
            screen: config,
            icon: :logo,
            text: "Government Center",
            time: ~U[2020-04-06T10:00:00Z]
          },
          3
        )

      expected_departures = [
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{type: :normal_section, rows: []},
            %{type: :normal_section, rows: []}
          ],
          slot_names: [:main_content_zero]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{type: :normal_section, rows: []},
            %{type: :normal_section, rows: []}
          ],
          slot_names: [:main_content_one]
        },
        %DeparturesWidget{
          screen: config,
          section_data: [
            %{type: :normal_section, rows: []},
            %{type: :normal_section, rows: []}
          ],
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.candidate_instances(
          config,
          now,
          fetch_stop_fn,
          fetch_section_departures_fn,
          fetch_alerts_or_empty_list_fn
        )

      assert Enum.all?(expected_headers, &Enum.member?(actual_instances, &1))
      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end
  end

  describe "header_instances/3" do
    test "returns expected header", %{config_primary_and_secondary: config} do
      now = ~U[2020-04-06T10:00:00Z]
      fetch_stop_name_fn = fn _ -> "Test Stop" end

      expected_headers =
        %NormalHeader{
          screen: config,
          icon: :logo,
          text: "Test Stop",
          time: now
        }
        |> List.duplicate(3)

      actual_instances =
        Dup.header_instances(
          config,
          now,
          fetch_stop_name_fn
        )

      Enum.all?(expected_headers, &Enum.member?(actual_instances, &1))
    end
  end

  describe "departures_instances/4" do
    test "returns primary and secondary departures", %{
      config_primary_and_secondary: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_alerts_or_empty_list_fn: fetch_alerts_or_empty_list_fn
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
        Dup.departures_instances(
          config,
          now,
          fetch_section_departures_fn,
          fetch_alerts_or_empty_list_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns only primary departures if secondary is missing", %{
      config_only_primary: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_alerts_or_empty_list_fn: fetch_alerts_or_empty_list_fn
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
        Dup.departures_instances(
          config,
          now,
          fetch_section_departures_fn,
          fetch_alerts_or_empty_list_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns 4 departures if only one section", %{
      config_one_section: config,
      fetch_section_departures_fn: fetch_section_departures_fn,
      fetch_alerts_or_empty_list_fn: fetch_alerts_or_empty_list_fn
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
        Dup.departures_instances(
          config,
          now,
          fetch_section_departures_fn,
          fetch_alerts_or_empty_list_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end

    test "returns headway sections for temporary terminal", %{
      config_one_section: config,
      fetch_section_departures_fn: fetch_section_departures_fn
    } do
      now = ~U[2020-04-06T10:00:00Z]

      fetch_alerts_or_empty_list_fn = fn
        [
          direction_id: :both,
          route_ids: [],
          route_types: [:light_rail, :subway],
          stop_ids: ["stop B"]
        ] ->
          [
            struct(Alert,
              effect: :suspension,
              informed_entities: [%{stop: "stop B"}, %{stop: "stop C"}]
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
        Dup.departures_instances(
          config,
          now,
          fetch_section_departures_fn,
          fetch_alerts_or_empty_list_fn
        )

      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
    end
  end
end
