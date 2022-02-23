defmodule Screens.V2.WidgetInstance.ElevatorStatusTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance
  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{ElevatorStatus, PreFare}
  alias Screens.Config.V2.Header.CurrentStopName

  setup do
    %{
      instance: %WidgetInstance.ElevatorStatus{
        screen: %Screen{
          app_params: %PreFare{
            elevator_status: %ElevatorStatus{
              parent_station_id: "place-foo",
              platform_stop_ids: []
            },
            header: %CurrentStopName{stop_name: "Test Station"}
          },
          vendor: nil,
          device_id: nil,
          name: nil,
          app_id: nil
        },
        alerts: [
          %Alert{
            effect: :elevator_closure,
            informed_entities: [
              %{stop: "place-bar", facility: "1"}
            ],
            active_period: [{~U[2022-01-01T00:00:00Z], ~U[2022-01-01T22:00:00Z]}]
          },
          %Alert{
            effect: :elevator_closure,
            informed_entities: [
              %{stop: "place-foo", facility: "1"}
            ],
            active_period: [{~U[2022-01-01T00:00:00Z], ~U[2022-01-01T22:00:00Z]}]
          }
        ],
        facility_id_to_name: %{"1" => "Elevator 1"},
        station_id_to_name: %{"place-foo" => "Foo Station", "place-bar" => "Bar Station"},
        station_id_to_icons: %{"place-foo" => [:red], "place-bar" => [:red]},
        now: ~U[2022-01-01T10:00:00Z],
        stop_sequences: [["place-foo"]]
      },
      one_active_at_home_instance: %WidgetInstance.ElevatorStatus{
        screen: %Screen{
          app_params: %PreFare{
            elevator_status: %ElevatorStatus{
              parent_station_id: "place-foo",
              platform_stop_ids: []
            },
            header: %CurrentStopName{stop_name: "Test Station"}
          },
          vendor: nil,
          device_id: nil,
          name: nil,
          app_id: nil
        },
        alerts: [
          %Alert{
            effect: :elevator_closure,
            informed_entities: [
              %{stop: "place-foo", facility: "1"}
            ],
            active_period: [{~U[2022-01-01T00:00:00Z], ~U[2022-01-01T22:00:00Z]}]
          }
        ],
        facility_id_to_name: %{"1" => "Elevator 1"},
        station_id_to_name: %{"place-foo" => "Foo Station"},
        station_id_to_icons: %{"place-foo" => [:red]},
        now: ~U[2022-01-01T10:00:00Z],
        stop_sequences: [["place-foo"]]
      },
      one_active_elsewhere_instance: %WidgetInstance.ElevatorStatus{
        screen: %Screen{
          app_params: %PreFare{
            elevator_status: %ElevatorStatus{
              parent_station_id: "place-foo",
              platform_stop_ids: []
            },
            header: %CurrentStopName{stop_name: "Test Station"}
          },
          vendor: nil,
          device_id: nil,
          name: nil,
          app_id: nil
        },
        alerts: [
          %Alert{
            effect: :elevator_closure,
            informed_entities: [
              %{stop: "place-bar", facility: "1"}
            ],
            active_period: [{~U[2022-01-01T00:00:00Z], ~U[2022-01-01T22:00:00Z]}]
          }
        ],
        facility_id_to_name: %{"1" => "Elevator 1"},
        station_id_to_name: %{"place-bar" => "Bar Station"},
        station_id_to_icons: %{"place-bar" => [:red]},
        now: ~U[2022-01-01T10:00:00Z],
        stop_sequences: [["place-foo"]]
      },
      one_upcoming_at_home_instance: %WidgetInstance.ElevatorStatus{
        screen: %Screen{
          app_params: %PreFare{
            elevator_status: %ElevatorStatus{
              parent_station_id: "place-foo",
              platform_stop_ids: []
            },
            header: %CurrentStopName{stop_name: "Test Station"}
          },
          vendor: nil,
          device_id: nil,
          name: nil,
          app_id: nil
        },
        alerts: [
          %Alert{
            effect: :elevator_closure,
            informed_entities: [
              %{stop: "place-foo", facility: "1"}
            ],
            active_period: [{~U[2022-02-01T00:00:00Z], ~U[2022-02-01T22:00:00Z]}]
          }
        ],
        facility_id_to_name: %{"1" => "Elevator 1"},
        station_id_to_name: %{"place-foo" => "Foo Station"},
        station_id_to_icons: %{"place-foo" => [:red]},
        now: ~U[2022-01-01T10:00:00Z],
        stop_sequences: [["place-foo"]]
      },
      one_active_on_connecting_line_instance: %WidgetInstance.ElevatorStatus{
        screen: %Screen{
          app_params: %PreFare{
            elevator_status: %ElevatorStatus{
              parent_station_id: "place-foo",
              platform_stop_ids: []
            },
            header: %CurrentStopName{stop_name: "Test Station"}
          },
          vendor: nil,
          device_id: nil,
          name: nil,
          app_id: nil
        },
        alerts: [
          %Alert{
            effect: :elevator_closure,
            informed_entities: [
              %{stop: "place-bar", facility: "1"},
              %{stop: "123", facility: "1"}
            ],
            active_period: [{~U[2022-01-01T00:00:00Z], ~U[2022-01-01T22:00:00Z]}]
          }
        ],
        facility_id_to_name: %{"1" => "Elevator 1"},
        station_id_to_name: %{"place-bar" => "Bar Station", "place-foo" => "Foo Station"},
        station_id_to_icons: %{"place-bar" => [:red], "place-foo" => [:red]},
        now: ~U[2022-01-01T10:00:00Z],
        stop_sequences: [["place-foo", "place-bar", "123"]]
      }
    }
  end

  describe "priority/1" do
    test "returns 2", %{instance: instance} do
      assert [2] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize/1" do
    test "returns a detail and list page for one active at-home", %{
      one_active_at_home_instance: instance
    } do
      expected_result = %{
        pages: [
          %Screens.V2.WidgetInstance.ElevatorStatus.DetailPage{
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
          %Screens.V2.WidgetInstance.ElevatorStatus.ListPage{
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

    test "returns a list page for one active elsewhere", %{
      one_active_elsewhere_instance: instance
    } do
      expected_result = %{
        pages: [
          %Screens.V2.WidgetInstance.ElevatorStatus.ListPage{
            stations: [
              %{
                name: "Bar Station",
                icons: [:red],
                is_at_home_stop: false,
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

    test "returns a detail page for one upcoming at-home", %{
      one_upcoming_at_home_instance: instance
    } do
      expected_result = %{
        pages: [
          %Screens.V2.WidgetInstance.ElevatorStatus.DetailPage{
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

    test "returns a detail page for one active on connecting line", %{
      one_active_on_connecting_line_instance: instance
    } do
      expected_result = %{
        pages: [
          %Screens.V2.WidgetInstance.ElevatorStatus.ListPage{
            stations: [
              %{
                name: "Bar Station",
                icons: [:red],
                is_at_home_stop: false,
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
          },
          %Screens.V2.WidgetInstance.ElevatorStatus.DetailPage{
            station: %{
              name: "Bar Station",
              icons: [:red],
              is_at_home_stop: false,
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
          }
        ]
      }

      assert expected_result == WidgetInstance.serialize(instance)
    end

    test "returns ordered list of pages", %{instance: instance} do
      expected_result = %{
        pages: [
          %Screens.V2.WidgetInstance.ElevatorStatus.DetailPage{
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
          %Screens.V2.WidgetInstance.ElevatorStatus.ListPage{
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
              },
              %{
                name: "Bar Station",
                icons: [:red],
                is_at_home_stop: false,
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
  end

  describe "slot_names/1" do
    test "returns lower_right", %{instance: instance} do
      assert [:lower_right] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns elevator_status", %{instance: instance} do
      assert :elevator_status == WidgetInstance.widget_type(instance)
    end
  end

  describe "audio_serialize/1" do
    test "returns empty string", %{instance: instance} do
      assert %{} == WidgetInstance.audio_serialize(instance)
    end
  end

  describe "audio_sort_key/1" do
    test "returns 0", %{instance: instance} do
      assert 0 == WidgetInstance.audio_sort_key(instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns false", %{instance: instance} do
      refute WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns ElevatorStatusView", %{instance: instance} do
      assert ScreensWeb.V2.Audio.ElevatorStatusView == WidgetInstance.audio_view(instance)
    end
  end
end
