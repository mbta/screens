defmodule Screens.V2.WidgetInstance.SubwayStatusTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{BusShelter, Departures, PreFare}
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.SubwayStatus

  describe "priority/1" do
    test "returns high priority for a flex zone widget" do
      instance = %SubwayStatus{subway_alerts: []}
      assert [2, 1] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize_route/2" do
    test "returns normal service when there are no alerts" do
      blue_line_alerts = []
      grouped_alerts = %{"Blue" => blue_line_alerts}
      assert %{status: "Normal Service"} = SubwayStatus.serialize_route(grouped_alerts, "Blue")
    end

    test "handles multiple alerts" do
      blue_line_alerts = [
        %Alert{effect: :shuttle},
        %Alert{effect: :suspension}
      ]

      grouped_alerts = %{"Blue" => blue_line_alerts}
      assert %{status: "2 alerts"} = SubwayStatus.serialize_route(grouped_alerts, "Blue")
    end

    test "handles shuttle alert" do
      blue_line_alerts = [
        %Alert{
          effect: :shuttle,
          informed_entities: [
            %{stop: "place-aport"},
            %{stop: "place-mvbcl"},
            %{stop: "place-aqucl"}
          ]
        }
      ]

      grouped_alerts = %{"Blue" => blue_line_alerts}

      assert %{
               status: "Shuttle Buses",
               location: %{full: "Airport to Aquarium", abbrev: "Airport to Aquarium"}
             } = SubwayStatus.serialize_route(grouped_alerts, "Blue")
    end

    test "handles whole line shuttle alert" do
      blue_line_alerts = [
        %Alert{
          effect: :shuttle,
          informed_entities: [%{route: "Blue", stop: nil, direction_id: nil}]
        }
      ]

      grouped_alerts = %{"Blue" => blue_line_alerts}

      assert %{status: "Shuttle Buses", location: nil} =
               SubwayStatus.serialize_route(grouped_alerts, "Blue")
    end

    test "handles suspension alert" do
      blue_line_alerts = [
        %Alert{
          effect: :suspension,
          informed_entities: [
            %{stop: "place-aport"},
            %{stop: "place-mvbcl"},
            %{stop: "place-aqucl"}
          ]
        }
      ]

      grouped_alerts = %{"Blue" => blue_line_alerts}

      assert %{
               status: "Suspension",
               location: %{full: "Airport to Aquarium", abbrev: "Airport to Aquarium"}
             } = SubwayStatus.serialize_route(grouped_alerts, "Blue")
    end

    test "handles whole line suspension alert" do
      blue_line_alerts = [
        %Alert{
          effect: :suspension,
          informed_entities: [%{route: "Blue", stop: nil, direction_id: nil}]
        }
      ]

      grouped_alerts = %{"Blue" => blue_line_alerts}

      assert %{status: "SERVICE SUSPENDED", location: nil} =
               SubwayStatus.serialize_route(grouped_alerts, "Blue")
    end

    test "handles delay alert" do
      blue_line_alerts = [
        %Alert{
          effect: :delay,
          severity: 3,
          informed_entities: [%{route: "Blue", stop: nil, direction_id: nil}]
        }
      ]

      grouped_alerts = %{"Blue" => blue_line_alerts}

      assert %{status: "Delays up to 10m", location: nil} =
               SubwayStatus.serialize_route(grouped_alerts, "Blue")
    end

    test "handles directional delay alert" do
      blue_line_alerts = [
        %Alert{
          effect: :delay,
          severity: 9,
          informed_entities: [%{route: "Blue", stop: nil, direction_id: 1}]
        }
      ]

      grouped_alerts = %{"Blue" => blue_line_alerts}

      assert %{
               status: "Delays over 60m",
               location: %{full: "Eastbound", abbrev: "Eastbound"}
             } = SubwayStatus.serialize_route(grouped_alerts, "Blue")
    end

    test "handles single station closure" do
      blue_line_alerts = [
        %Alert{effect: :station_closure, informed_entities: [%{stop: "place-orhte"}]}
      ]

      grouped_alerts = %{"Blue" => blue_line_alerts}

      assert %{status: "Bypassing", location: %{full: "Orient Heights", abbrev: "Orient Hts"}} =
               SubwayStatus.serialize_route(grouped_alerts, "Blue")
    end

    test "handles 2 station closure" do
      blue_line_alerts = [
        %Alert{
          effect: :station_closure,
          informed_entities: [%{stop: "place-orhte"}, %{stop: "place-rbmnl"}]
        }
      ]

      grouped_alerts = %{"Blue" => blue_line_alerts}

      assert %{
               status: "Bypassing",
               location: %{
                 full: "Orient Heights and Revere Beach",
                 abbrev: "Orient Hts and Revere Bch"
               }
             } = SubwayStatus.serialize_route(grouped_alerts, "Blue")
    end

    test "handles 3 station closure" do
      blue_line_alerts = [
        %Alert{
          effect: :station_closure,
          informed_entities: [
            %{stop: "place-orhte"},
            %{stop: "place-rbmnl"},
            %{stop: "place-gover"}
          ]
        }
      ]

      grouped_alerts = %{"Blue" => blue_line_alerts}

      assert %{status: "Bypassing", location: %{full: "3 stops", abbrev: "3 stops"}} =
               SubwayStatus.serialize_route(grouped_alerts, "Blue")
    end
  end

  describe "serialize_green_line/1" do
    test "handles single branch shuttle" do
      green_b_alerts = [
        %Alert{
          effect: :shuttle,
          informed_entities: [
            %{route: "Green-B", stop: "place-chill"},
            %{route: "Green-B", stop: "place-sougr"},
            %{route: "Green-B", stop: "place-lake"}
          ]
        }
      ]

      grouped_alerts = %{"Green-B" => green_b_alerts}

      assert %{
               branch: "Green-B",
               location: %{
                 full: "Chestnut Hill Avenue to Boston College",
                 abbrev: "Chestnut Hl to Boston Coll"
               },
               status: "Shuttle Buses",
               type: :single
             } = SubwayStatus.serialize_green_line(grouped_alerts)
    end

    test "handles concurrent branch shuttles" do
      green_b_alerts = [
        %Alert{
          effect: :shuttle,
          informed_entities: [
            %{route: "Green-B", stop: "place-chill"},
            %{route: "Green-B", stop: "place-sougr"},
            %{route: "Green-B", stop: "place-lake"}
          ]
        }
      ]

      green_d_alerts = [
        %Alert{
          effect: :shuttle,
          informed_entities: [
            %{route: "Green-D", stop: "place-newto"},
            %{route: "Green-D", stop: "place-newtn"},
            %{route: "Green-D", stop: "place-eliot"}
          ]
        }
      ]

      grouped_alerts = %{
        "Green-B" => green_b_alerts,
        "Green-D" => green_d_alerts
      }

      assert %{statuses: [[["Green-B", "Green-D"], "Shuttle Buses"]], type: :multiple} ==
               SubwayStatus.serialize_green_line(grouped_alerts)
    end

    test "handles concurrent branch shuttle and suspension" do
      green_b_alerts = [
        %Alert{
          effect: :shuttle,
          informed_entities: [
            %{route: "Green-B", stop: "place-chill"},
            %{route: "Green-B", stop: "place-sougr"},
            %{route: "Green-B", stop: "place-lake"}
          ]
        }
      ]

      green_d_alerts = [
        %Alert{
          effect: :suspension,
          informed_entities: [
            %{route: "Green-D", stop: "place-newto"},
            %{route: "Green-D", stop: "place-newtn"},
            %{route: "Green-D", stop: "place-eliot"}
          ]
        }
      ]

      grouped_alerts = %{
        "Green-B" => green_b_alerts,
        "Green-D" => green_d_alerts
      }

      assert %{
               statuses: [[["Green-B"], "Shuttle Buses"], [["Green-D"], "Suspension"]],
               type: :multiple
             } ==
               SubwayStatus.serialize_green_line(grouped_alerts)
    end

    test "handles trunk alert" do
      trunk_alerts = [
        %Alert{
          effect: :shuttle,
          informed_entities: [
            %{route: "Green-B", stop: "place-pktrm"},
            %{route: "Green-B", stop: "place-boyls"},
            %{route: "Green-B", stop: "place-armnl"},
            %{route: "Green-B", stop: "place-coecl"},
            %{route: "Green-C", stop: "place-pktrm"},
            %{route: "Green-C", stop: "place-boyls"},
            %{route: "Green-C", stop: "place-armnl"},
            %{route: "Green-C", stop: "place-coecl"},
            %{route: "Green-D", stop: "place-pktrm"},
            %{route: "Green-D", stop: "place-boyls"},
            %{route: "Green-D", stop: "place-armnl"},
            %{route: "Green-D", stop: "place-coecl"},
            %{route: "Green-E", stop: "place-pktrm"},
            %{route: "Green-E", stop: "place-boyls"},
            %{route: "Green-E", stop: "place-armnl"},
            %{route: "Green-E", stop: "place-coecl"}
          ]
        }
      ]

      grouped_alerts = %{
        "Green-B" => trunk_alerts,
        "Green-C" => trunk_alerts,
        "Green-D" => trunk_alerts,
        "Green-E" => trunk_alerts
      }

      assert %{
               location: %{full: "Park Street to Copley", abbrev: "Park St to Copley"},
               status: "Shuttle Buses",
               type: :single
             } = SubwayStatus.serialize_green_line(grouped_alerts)
    end

    test "handles normal service" do
      grouped_alerts = %{}

      assert %{status: "Normal Service", type: :single} =
               SubwayStatus.serialize_green_line(grouped_alerts)
    end

    test "handles alert affecting all branches" do
      alert = [
        %Alert{
          effect: :delay,
          severity: 3,
          informed_entities: [
            %{route: "Green-B", direction_id: nil, stop: nil},
            %{route: "Green-C", direction_id: nil, stop: nil},
            %{route: "Green-D", direction_id: nil, stop: nil},
            %{route: "Green-E", direction_id: nil, stop: nil}
          ]
        }
      ]

      grouped_alerts = %{
        "Green-B" => alert,
        "Green-C" => alert,
        "Green-D" => alert,
        "Green-E" => alert
      }

      assert %{
               location: nil,
               status: "Delays up to 10m",
               type: :single
             } = SubwayStatus.serialize_green_line(grouped_alerts)
    end

    test "handles directional delay alert" do
      alert = [
        %Alert{
          effect: :delay,
          severity: 9,
          informed_entities: [
            %{route: "Green-B", direction_id: 1, stop: nil},
            %{route: "Green-C", direction_id: 1, stop: nil},
            %{route: "Green-D", direction_id: 1, stop: nil},
            %{route: "Green-E", direction_id: 1, stop: nil}
          ]
        }
      ]

      grouped_alerts = %{
        "Green-B" => alert,
        "Green-C" => alert,
        "Green-D" => alert,
        "Green-E" => alert
      }

      assert %{
               status: "Delays over 60m",
               location: %{full: "Eastbound", abbrev: "Eastbound"}
             } = SubwayStatus.serialize_green_line(grouped_alerts)
    end
  end

  describe "slot_names/1" do
    test "returns large flex zone" do
      instance = %SubwayStatus{subway_alerts: []}
      assert [:large] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns subway status" do
      instance = %SubwayStatus{subway_alerts: []}
      assert :subway_status == WidgetInstance.widget_type(instance)
    end
  end

  describe "audio_serialize/1" do
    test "returns same result as serialize/1" do
      instance = %SubwayStatus{
        subway_alerts: []
      }

      assert WidgetInstance.serialize(instance) == WidgetInstance.audio_serialize(instance)
    end
  end

  describe "audio_sort_key/1" do
    test "returns [1]" do
      instance = %SubwayStatus{}
      assert [1] == WidgetInstance.audio_sort_key(instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns true for PreFare" do
      instance = %SubwayStatus{
        screen: %Screen{
          app_params: struct(PreFare),
          vendor: nil,
          device_id: nil,
          name: nil,
          app_id: nil
        }
      }

      assert WidgetInstance.audio_valid_candidate?(instance)
    end

    test "returns false for BusShelter" do
      instance = %SubwayStatus{
        screen: %Screen{
          app_params: %BusShelter{
            departures: %Departures{
              sections: []
            },
            header: nil,
            footer: nil,
            alerts: nil
          },
          vendor: nil,
          device_id: nil,
          name: nil,
          app_id: nil
        }
      }

      refute WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns SubwayStatusView" do
      instance = %SubwayStatus{}
      assert ScreensWeb.V2.Audio.SubwayStatusView == WidgetInstance.audio_view(instance)
    end
  end
end
