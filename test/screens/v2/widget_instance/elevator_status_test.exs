defmodule WidgetInstance.ElevatorStatusTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance
  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{ElevatorStatus, PreFare}

  # Convenience function to build an elevator alert
  defp alert(opts) do
    %Alert{
      effect: :elevator_closure,
      informed_entities: opts[:informed_entities] || [],
      active_period: opts[:active_period] || []
    }
  end

  # Convenience function to build an informed entity
  defp ie(opts), do: %{stop: opts[:stop], facility: opts[:facility]}

  setup do
    home_station_id = "place-foo"
    home_platform_ids = ["1001", "1002"]

    connecting_station_id = "place-bar"
    connecting_platform_ids = ["1003", "1004"]

    elsewhere_station_id = "place-baz"
    elsewhere_platform_ids = ["2001", "2002"]

    other_elsewhere_station_id = "place-qux"
    other_elsewhere_platform_ids = ["2003", "2004"]

    screen_config =
      struct(Screen, %{
        app_params:
          struct(PreFare, %{
            elevator_status: %ElevatorStatus{
              parent_station_id: home_station_id,
              platform_stop_ids: home_platform_ids
            }
          })
      })

    now = ~U[2022-01-01T10:00:00Z]
    happening_now_active_period = [{~U[2022-01-01T00:00:00Z], ~U[2022-01-01T22:00:00Z]}]
    upcoming_active_period = [{~U[2022-02-01T00:00:00Z], ~U[2022-02-01T22:00:00Z]}]

    facility_id_to_name = for id <- 1..9, into: %{}, do: {to_string(id), "Elevator #{id}"}

    station_id_to_name = %{
      "place-foo" => "Foo Station",
      "place-bar" => "Bar Station",
      "place-baz" => "Baz Station",
      "place-qux" => "Qux Station"
    }

    stop_sequences = [
      ["1001", "1003", "1005"],
      ["1002", "1004", "1006"]
    ]

    station_id_to_icons = %{
      "place-foo" => [:red],
      "place-bar" => [:red, :orange, :bus],
      "place-baz" => [:green],
      "place-qux" => [:green]
    }

    home_ies = fn facility ->
      [ie(stop: home_station_id, facility: facility)] ++
        Enum.map(home_platform_ids, &ie(stop: &1, facility: facility))
    end

    connecting_ies = fn facility ->
      [ie(stop: connecting_station_id, facility: facility)] ++
        Enum.map(connecting_platform_ids, &ie(stop: &1, facility: facility))
    end

    elsewhere_ies = fn facility ->
      [ie(stop: elsewhere_station_id, facility: facility)] ++
        Enum.map(elsewhere_platform_ids, &ie(stop: &1, facility: facility))
    end

    other_elsewhere_ies = fn facility ->
      [ie(stop: other_elsewhere_station_id, facility: facility)] ++
        Enum.map(other_elsewhere_platform_ids, &ie(stop: &1, facility: facility))
    end

    alert_active_home1 =
      alert(
        informed_entities: home_ies.("1"),
        active_period: happening_now_active_period
      )

    alert_active_home2 =
      alert(
        informed_entities: home_ies.("5"),
        active_period: happening_now_active_period
      )

    alert_upcoming_home1 =
      alert(
        informed_entities: home_ies.("1"),
        active_period: upcoming_active_period
      )

    alert_upcoming_home2 =
      alert(
        informed_entities: home_ies.("5"),
        active_period: upcoming_active_period
      )

    alert_active_connecting_station1 =
      alert(
        informed_entities: connecting_ies.("2"),
        active_period: happening_now_active_period
      )

    alert_active_connecting_station2 =
      alert(
        informed_entities: connecting_ies.("6"),
        active_period: happening_now_active_period
      )

    alert_upcoming_connecting_station1 =
      alert(
        informed_entities: connecting_ies.("2"),
        active_period: upcoming_active_period
      )

    alert_upcoming_connecting_station2 =
      alert(
        informed_entities: connecting_ies.("6"),
        active_period: upcoming_active_period
      )

    alert_active_elsewhere1 =
      alert(
        informed_entities: elsewhere_ies.("3"),
        active_period: happening_now_active_period
      )

    alert_active_elsewhere2 =
      alert(
        informed_entities: elsewhere_ies.("7"),
        active_period: happening_now_active_period
      )

    alert_upcoming_elsewhere1 =
      alert(
        informed_entities: elsewhere_ies.("3"),
        active_period: upcoming_active_period
      )

    alert_upcoming_elsewhere2 =
      alert(
        informed_entities: elsewhere_ies.("7"),
        active_period: upcoming_active_period
      )

    alert_active_other_elsewhere1 =
      alert(
        informed_entities: other_elsewhere_ies.("4"),
        active_period: happening_now_active_period
      )

    alert_active_other_elsewhere2 =
      alert(
        informed_entities: other_elsewhere_ies.("8"),
        active_period: happening_now_active_period
      )

    alert_active_other_elsewhere3 =
      alert(
        informed_entities: other_elsewhere_ies.("9"),
        active_period: happening_now_active_period
      )

    alert_upcoming_other_elsewhere1 =
      alert(
        informed_entities: other_elsewhere_ies.("4"),
        active_period: upcoming_active_period
      )

    alert_upcoming_other_elsewhere2 =
      alert(
        informed_entities: other_elsewhere_ies.("8"),
        active_period: upcoming_active_period
      )

    alert_upcoming_other_elsewhere3 =
      alert(
        informed_entities: other_elsewhere_ies.("9"),
        active_period: upcoming_active_period
      )

    widget = fn opts ->
      %WidgetInstance.ElevatorStatus{
        screen: screen_config,
        alerts: opts[:alerts] || [],
        facility_id_to_name: facility_id_to_name,
        station_id_to_name: station_id_to_name,
        station_id_to_icons: station_id_to_icons,
        now: now,
        stop_sequences: stop_sequences
      }
    end

    %{
      no_alerts_instance: widget.(alerts: []),

      # Scenario A: closure at home elevator
      # (not possible until we implement elevator screens)

      # Scenario B: one or more active closure at home station
      one_active_at_home_instance: widget.(alerts: [alert_active_home1]),
      two_active_at_home_instance: widget.(alerts: [alert_active_home1, alert_active_home2]),
      all_active_instance:
        widget.(
          alerts: [
            alert_active_home1,
            alert_active_home2,
            alert_active_connecting_station1,
            alert_active_connecting_station2,
            alert_active_elsewhere1,
            alert_active_elsewhere2,
            alert_active_other_elsewhere1,
            alert_active_other_elsewhere2,
            alert_active_other_elsewhere3
          ]
        ),
      all_mixed_instance:
        widget.(
          alerts: [
            alert_active_home1,
            alert_upcoming_home2,
            alert_active_connecting_station1,
            alert_upcoming_connecting_station2,
            alert_active_elsewhere1,
            alert_upcoming_elsewhere2,
            alert_active_other_elsewhere1,
            alert_upcoming_other_elsewhere2,
            alert_upcoming_other_elsewhere3
          ]
        ),
      one_active_at_home_many_active_elsewhere_instance:
        widget.(
          alerts: [
            alert_active_home1,
            alert_active_connecting_station1,
            alert_active_connecting_station2,
            alert_active_elsewhere1,
            alert_active_elsewhere2,
            alert_active_other_elsewhere1,
            alert_active_other_elsewhere2,
            alert_active_other_elsewhere3
          ]
        ),

      # Scenario C: no active closures at home station
      one_upcoming_at_home_instance: widget.(alerts: [alert_upcoming_home1]),
      all_upcoming_instance:
        widget.(
          alerts: [
            alert_upcoming_home1,
            alert_upcoming_home2,
            alert_upcoming_connecting_station1,
            alert_upcoming_connecting_station2,
            alert_upcoming_elsewhere1,
            alert_upcoming_elsewhere2,
            alert_upcoming_other_elsewhere1,
            alert_upcoming_other_elsewhere2,
            alert_upcoming_other_elsewhere3
          ]
        ),
      one_active_on_connecting_line_instance: widget.(alerts: [alert_active_connecting_station1]),
      one_active_elsewhere_instance: widget.(alerts: [alert_active_elsewhere1]),
      non_home_active_instance:
        widget.(
          alerts: [
            alert_active_connecting_station1,
            alert_active_connecting_station2,
            alert_active_elsewhere1,
            alert_active_elsewhere2,
            alert_active_other_elsewhere1,
            alert_active_other_elsewhere2,
            alert_active_other_elsewhere3
          ]
        ),
      non_home_upcoming_instance:
        widget.(
          alerts: [
            alert_upcoming_connecting_station1,
            alert_upcoming_connecting_station2,
            alert_upcoming_elsewhere1,
            alert_upcoming_elsewhere2,
            alert_upcoming_other_elsewhere1,
            alert_upcoming_other_elsewhere2,
            alert_upcoming_other_elsewhere3
          ]
        ),
      non_home_mixed_instance:
        widget.(
          alerts: [
            alert_active_connecting_station1,
            alert_upcoming_connecting_station2,
            alert_active_elsewhere1,
            alert_upcoming_elsewhere2,
            alert_active_other_elsewhere1,
            alert_upcoming_other_elsewhere2,
            alert_active_other_elsewhere3
          ]
        )
    }
  end

  describe "priority/1" do
    test "returns 2", %{one_active_at_home_instance: instance} do
      assert [2] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns an empty list page when there are no alerts", %{no_alerts_instance: instance} do
      expected_result = %{
        pages: [%WidgetInstance.ElevatorStatus.ListPage{stations: []}]
      }

      assert expected_result == WidgetInstance.serialize(instance)
    end

    test "returns a detail and list page for one active at-home", %{
      one_active_at_home_instance: instance
    } do
      expected_result = %{
        pages: [
          %WidgetInstance.ElevatorStatus.DetailPage{
            station: %{
              name: "Foo Station",
              icons: [:red],
              is_at_home_stop: true,
              elevator_closures: [
                %{
                  description: nil,
                  elevator_id: "1",
                  elevator_name: "Elevator 1",
                  timeframe: %{
                    active_period: %{
                      "start" => "2022-01-01T00:00:00Z",
                      "end" => "2022-01-01T22:00:00Z"
                    },
                    happening_now: true
                  },
                  header_text: nil
                }
              ]
            }
          },
          %WidgetInstance.ElevatorStatus.ListPage{
            stations: [
              %{
                name: "Foo Station",
                icons: [:red],
                is_at_home_stop: true,
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "1",
                    elevator_name: "Elevator 1",
                    timeframe: %{
                      active_period: %{
                        "start" => "2022-01-01T00:00:00Z",
                        "end" => "2022-01-01T22:00:00Z"
                      },
                      happening_now: true
                    },
                    header_text: nil
                  }
                ]
              }
            ]
          }
        ]
      }

      assert expected_result == WidgetInstance.serialize(instance)
    end

    test "returns two detail and one list page for two active at home", %{
      two_active_at_home_instance: instance
    } do
      expected_result = %{
        pages: [
          %WidgetInstance.ElevatorStatus.DetailPage{
            station: %{
              name: "Foo Station",
              icons: [:red],
              is_at_home_stop: true,
              elevator_closures: [
                %{
                  description: nil,
                  elevator_id: "1",
                  elevator_name: "Elevator 1",
                  timeframe: %{
                    active_period: %{
                      "start" => "2022-01-01T00:00:00Z",
                      "end" => "2022-01-01T22:00:00Z"
                    },
                    happening_now: true
                  },
                  header_text: nil
                }
              ]
            }
          },
          %WidgetInstance.ElevatorStatus.DetailPage{
            station: %{
              name: "Foo Station",
              icons: [:red],
              is_at_home_stop: true,
              elevator_closures: [
                %{
                  description: nil,
                  elevator_id: "5",
                  elevator_name: "Elevator 5",
                  timeframe: %{
                    active_period: %{
                      "start" => "2022-01-01T00:00:00Z",
                      "end" => "2022-01-01T22:00:00Z"
                    },
                    happening_now: true
                  },
                  header_text: nil
                }
              ]
            }
          },
          %WidgetInstance.ElevatorStatus.ListPage{
            stations: [
              %{
                name: "Foo Station",
                icons: [:red],
                is_at_home_stop: true,
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "1",
                    elevator_name: "Elevator 1",
                    timeframe: %{
                      active_period: %{
                        "start" => "2022-01-01T00:00:00Z",
                        "end" => "2022-01-01T22:00:00Z"
                      },
                      happening_now: true
                    },
                    header_text: nil
                  },
                  %{
                    description: nil,
                    elevator_id: "5",
                    elevator_name: "Elevator 5",
                    timeframe: %{
                      active_period: %{
                        "start" => "2022-01-01T00:00:00Z",
                        "end" => "2022-01-01T22:00:00Z"
                      },
                      happening_now: true
                    },
                    header_text: nil
                  }
                ]
              }
            ]
          }
        ]
      }

      assert expected_result == WidgetInstance.serialize(instance)
    end

    test "returns two detail pages and one list page for two active each at home + connecting, 4 active at elsewhere stations",
         %{all_active_instance: instance} do
      # Note: some content would appear on an additional list page, which gets truncated
      expected_result = %{
        pages: [
          %WidgetInstance.ElevatorStatus.DetailPage{
            station: %{
              name: "Foo Station",
              icons: [:red],
              is_at_home_stop: true,
              elevator_closures: [
                %{
                  description: nil,
                  elevator_id: "1",
                  elevator_name: "Elevator 1",
                  timeframe: %{
                    active_period: %{
                      "start" => "2022-01-01T00:00:00Z",
                      "end" => "2022-01-01T22:00:00Z"
                    },
                    happening_now: true
                  },
                  header_text: nil
                }
              ]
            }
          },
          %WidgetInstance.ElevatorStatus.DetailPage{
            station: %{
              name: "Foo Station",
              icons: [:red],
              is_at_home_stop: true,
              elevator_closures: [
                %{
                  description: nil,
                  elevator_id: "5",
                  elevator_name: "Elevator 5",
                  timeframe: %{
                    active_period: %{
                      "start" => "2022-01-01T00:00:00Z",
                      "end" => "2022-01-01T22:00:00Z"
                    },
                    happening_now: true
                  },
                  header_text: nil
                }
              ]
            }
          },
          %WidgetInstance.ElevatorStatus.ListPage{
            stations: [
              %{
                name: "Foo Station",
                icons: [:red],
                is_at_home_stop: true,
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "1",
                    elevator_name: "Elevator 1",
                    timeframe: %{
                      active_period: %{
                        "start" => "2022-01-01T00:00:00Z",
                        "end" => "2022-01-01T22:00:00Z"
                      },
                      happening_now: true
                    },
                    header_text: nil
                  },
                  %{
                    description: nil,
                    elevator_id: "5",
                    elevator_name: "Elevator 5",
                    timeframe: %{
                      active_period: %{
                        "start" => "2022-01-01T00:00:00Z",
                        "end" => "2022-01-01T22:00:00Z"
                      },
                      happening_now: true
                    },
                    header_text: nil
                  }
                ]
              },
              %{
                name: "Bar Station",
                icons: [:red, :orange, :bus],
                is_at_home_stop: false,
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "2",
                    elevator_name: "Elevator 2",
                    timeframe: %{
                      active_period: %{
                        "start" => "2022-01-01T00:00:00Z",
                        "end" => "2022-01-01T22:00:00Z"
                      },
                      happening_now: true
                    },
                    header_text: nil
                  },
                  %{
                    description: nil,
                    elevator_id: "6",
                    elevator_name: "Elevator 6",
                    timeframe: %{
                      active_period: %{
                        "start" => "2022-01-01T00:00:00Z",
                        "end" => "2022-01-01T22:00:00Z"
                      },
                      happening_now: true
                    },
                    header_text: nil
                  }
                ]
              },
              %{
                name: "Baz Station",
                icons: [:green],
                is_at_home_stop: false,
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "3",
                    elevator_name: "Elevator 3",
                    timeframe: %{
                      active_period: %{
                        "start" => "2022-01-01T00:00:00Z",
                        "end" => "2022-01-01T22:00:00Z"
                      },
                      happening_now: true
                    },
                    header_text: nil
                  },
                  %{
                    description: nil,
                    elevator_id: "7",
                    elevator_name: "Elevator 7",
                    timeframe: %{
                      active_period: %{
                        "start" => "2022-01-01T00:00:00Z",
                        "end" => "2022-01-01T22:00:00Z"
                      },
                      happening_now: true
                    },
                    header_text: nil
                  }
                ]
              }
            ]
          }
        ]
      }

      assert expected_result == WidgetInstance.serialize(instance)
    end

    test "returns one detail and one list page for a mix of active/upcoming at home, connecting, elsewhere",
         %{
           all_mixed_instance: instance
         } do
      expected_result = %{
        pages: [
          %WidgetInstance.ElevatorStatus.DetailPage{
            station: %{
              name: "Foo Station",
              icons: [:red],
              is_at_home_stop: true,
              elevator_closures: [
                %{
                  description: nil,
                  elevator_id: "1",
                  elevator_name: "Elevator 1",
                  header_text: nil,
                  timeframe: %{
                    active_period: %{
                      "end" => "2022-01-01T22:00:00Z",
                      "start" => "2022-01-01T00:00:00Z"
                    },
                    happening_now: true
                  }
                }
              ]
            }
          },
          %WidgetInstance.ElevatorStatus.ListPage{
            stations: [
              %{
                name: "Foo Station",
                icons: [:red],
                is_at_home_stop: true,
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "1",
                    elevator_name: "Elevator 1",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  }
                ]
              },
              %{
                name: "Bar Station",
                icons: [:red, :orange, :bus],
                is_at_home_stop: false,
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "2",
                    elevator_name: "Elevator 2",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  }
                ]
              },
              %{
                name: "Baz Station",
                icons: [:green],
                is_at_home_stop: false,
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "3",
                    elevator_name: "Elevator 3",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  }
                ]
              },
              %{
                name: "Qux Station",
                icons: [:green],
                is_at_home_stop: false,
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "4",
                    elevator_name: "Elevator 4",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  }
                ]
              }
            ]
          }
        ]
      }

      assert expected_result == WidgetInstance.serialize(instance)
    end

    test "returns one detail and two list pages for one active at home and many active on connecting + elsewhere",
         %{one_active_at_home_many_active_elsewhere_instance: instance} do
      # List view content spills onto a second page
      expected_result = %{
        pages: [
          %WidgetInstance.ElevatorStatus.DetailPage{
            station: %{
              elevator_closures: [
                %{
                  description: nil,
                  elevator_id: "1",
                  elevator_name: "Elevator 1",
                  header_text: nil,
                  timeframe: %{
                    active_period: %{
                      "end" => "2022-01-01T22:00:00Z",
                      "start" => "2022-01-01T00:00:00Z"
                    },
                    happening_now: true
                  }
                }
              ],
              icons: [:red],
              is_at_home_stop: true,
              name: "Foo Station"
            }
          },
          %WidgetInstance.ElevatorStatus.ListPage{
            stations: [
              %{
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "1",
                    elevator_name: "Elevator 1",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  }
                ],
                icons: [:red],
                is_at_home_stop: true,
                name: "Foo Station"
              },
              %{
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "2",
                    elevator_name: "Elevator 2",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  },
                  %{
                    description: nil,
                    elevator_id: "6",
                    elevator_name: "Elevator 6",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  }
                ],
                icons: [:red, :orange, :bus],
                is_at_home_stop: false,
                name: "Bar Station"
              },
              %{
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "3",
                    elevator_name: "Elevator 3",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  },
                  %{
                    description: nil,
                    elevator_id: "7",
                    elevator_name: "Elevator 7",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  }
                ],
                icons: [:green],
                is_at_home_stop: false,
                name: "Baz Station"
              }
            ]
          },
          %WidgetInstance.ElevatorStatus.ListPage{
            stations: [
              %{
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "1",
                    elevator_name: "Elevator 1",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  }
                ],
                icons: [:red],
                is_at_home_stop: true,
                name: "Foo Station"
              },
              %{
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "4",
                    elevator_name: "Elevator 4",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  },
                  %{
                    description: nil,
                    elevator_id: "8",
                    elevator_name: "Elevator 8",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  },
                  %{
                    description: nil,
                    elevator_id: "9",
                    elevator_name: "Elevator 9",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  }
                ],
                icons: [:green],
                is_at_home_stop: false,
                name: "Qux Station"
              }
            ]
          }
        ]
      }

      assert expected_result == WidgetInstance.serialize(instance)
    end

    test "returns a list page (empty) and a detail page for one upcoming at home", %{
      one_upcoming_at_home_instance: instance
    } do
      expected_result = %{
        pages: [
          %WidgetInstance.ElevatorStatus.ListPage{stations: []},
          %WidgetInstance.ElevatorStatus.DetailPage{
            station: %{
              name: "Foo Station",
              icons: [:red],
              is_at_home_stop: true,
              elevator_closures: [
                %{
                  description: nil,
                  elevator_id: "1",
                  elevator_name: "Elevator 1",
                  timeframe: %{
                    active_period: %{
                      "start" => "2022-02-01T00:00:00Z",
                      "end" => "2022-02-01T22:00:00Z"
                    },
                    happening_now: false
                  },
                  header_text: nil
                }
              ]
            }
          }
        ]
      }

      assert expected_result == WidgetInstance.serialize(instance)
    end

    test "returns list page (empty) followed by detail pages for several upcoming alerts", %{
      all_upcoming_instance: instance
    } do
      expected_result = %{
        pages: [
          %WidgetInstance.ElevatorStatus.ListPage{
            stations: []
          },
          %WidgetInstance.ElevatorStatus.DetailPage{
            station: %{
              name: "Foo Station",
              icons: [:red],
              is_at_home_stop: true,
              elevator_closures: [
                %{
                  description: nil,
                  elevator_id: "1",
                  elevator_name: "Elevator 1",
                  header_text: nil,
                  timeframe: %{
                    active_period: %{
                      "end" => "2022-02-01T22:00:00Z",
                      "start" => "2022-02-01T00:00:00Z"
                    },
                    happening_now: false
                  }
                }
              ]
            }
          },
          %WidgetInstance.ElevatorStatus.DetailPage{
            station: %{
              name: "Foo Station",
              icons: [:red],
              is_at_home_stop: true,
              elevator_closures: [
                %{
                  description: nil,
                  elevator_id: "5",
                  elevator_name: "Elevator 5",
                  header_text: nil,
                  timeframe: %{
                    active_period: %{
                      "end" => "2022-02-01T22:00:00Z",
                      "start" => "2022-02-01T00:00:00Z"
                    },
                    happening_now: false
                  }
                }
              ]
            }
          }
        ]
      }

      assert expected_result == WidgetInstance.serialize(instance)
    end

    test "returns a detail page for one active on connecting line", %{
      one_active_on_connecting_line_instance: instance
    } do
      expected_result = %{
        pages: [
          %WidgetInstance.ElevatorStatus.ListPage{
            stations: [
              %{
                name: "Bar Station",
                icons: [:red, :orange, :bus],
                is_at_home_stop: false,
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "2",
                    elevator_name: "Elevator 2",
                    timeframe: %{
                      active_period: %{
                        "start" => "2022-01-01T00:00:00Z",
                        "end" => "2022-01-01T22:00:00Z"
                      },
                      happening_now: true
                    },
                    header_text: nil
                  }
                ]
              }
            ]
          },
          %WidgetInstance.ElevatorStatus.DetailPage{
            station: %{
              name: "Bar Station",
              icons: [:red, :orange, :bus],
              is_at_home_stop: false,
              elevator_closures: [
                %{
                  description: nil,
                  elevator_id: "2",
                  elevator_name: "Elevator 2",
                  timeframe: %{
                    active_period: %{
                      "start" => "2022-01-01T00:00:00Z",
                      "end" => "2022-01-01T22:00:00Z"
                    },
                    happening_now: true
                  },
                  header_text: nil
                }
              ]
            }
          }
        ]
      }

      assert expected_result == WidgetInstance.serialize(instance)
    end

    test "returns a list page for one active elsewhere", %{
      one_active_elsewhere_instance: instance
    } do
      expected_result = %{
        pages: [
          %WidgetInstance.ElevatorStatus.ListPage{
            stations: [
              %{
                name: "Baz Station",
                icons: [:green],
                is_at_home_stop: false,
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "3",
                    elevator_name: "Elevator 3",
                    timeframe: %{
                      active_period: %{
                        "start" => "2022-01-01T00:00:00Z",
                        "end" => "2022-01-01T22:00:00Z"
                      },
                      happening_now: true
                    },
                    header_text: nil
                  }
                ]
              }
            ]
          }
        ]
      }

      assert expected_result == WidgetInstance.serialize(instance)
    end

    test "returns one list and two detail pages for active on connecting lines + elsewhere", %{
      non_home_active_instance: instance
    } do
      expected_result = %{
        pages: [
          %WidgetInstance.ElevatorStatus.ListPage{
            stations: [
              %{
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "2",
                    elevator_name: "Elevator 2",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  },
                  %{
                    description: nil,
                    elevator_id: "6",
                    elevator_name: "Elevator 6",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  }
                ],
                icons: [:red, :orange, :bus],
                is_at_home_stop: false,
                name: "Bar Station"
              },
              %{
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "3",
                    elevator_name: "Elevator 3",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  },
                  %{
                    description: nil,
                    elevator_id: "7",
                    elevator_name: "Elevator 7",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  }
                ],
                icons: [:green],
                is_at_home_stop: false,
                name: "Baz Station"
              },
              %{
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "4",
                    elevator_name: "Elevator 4",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  },
                  %{
                    description: nil,
                    elevator_id: "8",
                    elevator_name: "Elevator 8",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  },
                  %{
                    description: nil,
                    elevator_id: "9",
                    elevator_name: "Elevator 9",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  }
                ],
                icons: [:green],
                is_at_home_stop: false,
                name: "Qux Station"
              }
            ]
          },
          %WidgetInstance.ElevatorStatus.DetailPage{
            station: %{
              elevator_closures: [
                %{
                  description: nil,
                  elevator_id: "6",
                  elevator_name: "Elevator 6",
                  header_text: nil,
                  timeframe: %{
                    active_period: %{
                      "end" => "2022-01-01T22:00:00Z",
                      "start" => "2022-01-01T00:00:00Z"
                    },
                    happening_now: true
                  }
                }
              ],
              icons: [:red, :orange, :bus],
              is_at_home_stop: false,
              name: "Bar Station"
            }
          },
          %WidgetInstance.ElevatorStatus.DetailPage{
            station: %{
              elevator_closures: [
                %{
                  description: nil,
                  elevator_id: "2",
                  elevator_name: "Elevator 2",
                  header_text: nil,
                  timeframe: %{
                    active_period: %{
                      "end" => "2022-01-01T22:00:00Z",
                      "start" => "2022-01-01T00:00:00Z"
                    },
                    happening_now: true
                  }
                }
              ],
              icons: [:red, :orange, :bus],
              is_at_home_stop: false,
              name: "Bar Station"
            }
          }
        ]
      }

      assert expected_result == WidgetInstance.serialize(instance)
    end

    test "returns one list page for upcoming on connecting lines + elsewhere", %{
      non_home_upcoming_instance: instance
    } do
      # (We only include upcoming at home, no other upcoming closures)
      expected_result = %{
        pages: [%WidgetInstance.ElevatorStatus.ListPage{stations: []}]
      }

      assert expected_result == WidgetInstance.serialize(instance)
    end

    test "returns one list page and one detail page for a mix of active/upcoming on connecting lines + elsewhere",
         %{non_home_mixed_instance: instance} do
      expected_result = %{
        pages: [
          %WidgetInstance.ElevatorStatus.ListPage{
            stations: [
              %{
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "2",
                    elevator_name: "Elevator 2",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  }
                ],
                icons: [:red, :orange, :bus],
                is_at_home_stop: false,
                name: "Bar Station"
              },
              %{
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "3",
                    elevator_name: "Elevator 3",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  }
                ],
                icons: [:green],
                is_at_home_stop: false,
                name: "Baz Station"
              },
              %{
                elevator_closures: [
                  %{
                    description: nil,
                    elevator_id: "4",
                    elevator_name: "Elevator 4",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  },
                  %{
                    description: nil,
                    elevator_id: "9",
                    elevator_name: "Elevator 9",
                    header_text: nil,
                    timeframe: %{
                      active_period: %{
                        "end" => "2022-01-01T22:00:00Z",
                        "start" => "2022-01-01T00:00:00Z"
                      },
                      happening_now: true
                    }
                  }
                ],
                icons: [:green],
                is_at_home_stop: false,
                name: "Qux Station"
              }
            ]
          },
          %WidgetInstance.ElevatorStatus.DetailPage{
            station: %{
              elevator_closures: [
                %{
                  description: nil,
                  elevator_id: "2",
                  elevator_name: "Elevator 2",
                  header_text: nil,
                  timeframe: %{
                    active_period: %{
                      "end" => "2022-01-01T22:00:00Z",
                      "start" => "2022-01-01T00:00:00Z"
                    },
                    happening_now: true
                  }
                }
              ],
              icons: [:red, :orange, :bus],
              is_at_home_stop: false,
              name: "Bar Station"
            }
          }
        ]
      }

      assert expected_result == WidgetInstance.serialize(instance)
    end
  end

  describe "slot_names/1" do
    test "returns lower_right", %{one_active_at_home_instance: instance} do
      assert [:lower_right] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns elevator_status", %{one_active_at_home_instance: instance} do
      assert :elevator_status == WidgetInstance.widget_type(instance)
    end
  end

  describe "audio_serialize/1" do
    test "returns empty map", %{one_active_at_home_instance: instance} do
      assert %{} == WidgetInstance.audio_serialize(instance)
    end
  end

  describe "audio_sort_key/1" do
    test "returns [0]", %{one_active_at_home_instance: instance} do
      assert [0] == WidgetInstance.audio_sort_key(instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false", %{one_active_at_home_instance: instance} do
      refute WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns ElevatorStatusView", %{one_active_at_home_instance: instance} do
      assert ScreensWeb.V2.Audio.ElevatorStatusView == WidgetInstance.audio_view(instance)
    end
  end
end
