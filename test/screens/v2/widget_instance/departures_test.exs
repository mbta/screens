defmodule Screens.V2.WidgetInstance.DeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Config.Dup.Override.FreeTextLine
  alias Screens.Config.Screen
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Trips.Trip
  alias Screens.Vehicles.Vehicle
  alias Screens.V2.{Departure, WidgetInstance}
  alias Screens.V2.WidgetInstance.Departures
  alias Screens.V2.WidgetInstance.Serializer.RoutePill

  describe "priority/1" do
    test "returns 2" do
      instance = %Departures{section_data: []}
      assert [2] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize_section/1" do
    setup do
      %{
        bus_shelter_screen: %Screen{
          app_id: :bus_shelter_v2,
          vendor: :lg_mri,
          device_id: "TEST",
          name: "TEST",
          app_params: nil
        }
      }
    end

    test "returns serialized normal_section", %{bus_shelter_screen: bus_shelter_screen} do
      section = %{type: :normal_section, rows: []}

      assert %{type: :normal_section, rows: []} ==
               Departures.serialize_section(section, bus_shelter_screen)
    end

    test "returns serialized notice_section", %{bus_shelter_screen: bus_shelter_screen} do
      section = %{type: :notice_section, text: %{icon: :warning, text: []}}

      assert %{type: :notice_section, text: %{icon: :warning, text: []}} ==
               Departures.serialize_section(section, bus_shelter_screen)
    end

    test "returns serialized normal_section with notice", %{
      bus_shelter_screen: bus_shelter_screen
    } do
      section = %{type: :normal_section, rows: [%{text: %FreeTextLine{icon: nil, text: []}}]}

      assert %{type: :normal_section, rows: [%{type: :notice_row, text: %{icon: nil, text: []}}]} ==
               Departures.serialize_section(section, bus_shelter_screen)
    end
  end

  describe "group_consecutive_departures/2" do
    setup do
      %{
        bus_shelter_screen: %Screen{
          app_id: :bus_shelter_v2,
          vendor: :lg_mri,
          device_id: "TEST",
          name: "TEST",
          app_params: nil
        }
      }
    end

    test "groups consecutive departures with matching routes and headsigns", %{
      bus_shelter_screen: bus_shelter_screen
    } do
      d1 = %Departure{
        prediction: %Prediction{route: %Route{id: "1"}, trip: %Trip{headsign: "Nubian"}}
      }

      d2 = %Departure{
        prediction: %Prediction{route: %Route{id: "1"}, trip: %Trip{headsign: "Nubian"}}
      }

      d3 = %Departure{
        schedule: %Schedule{route: %Route{id: "22"}, trip: %Trip{headsign: "Ruggles"}}
      }

      d4 = %Departure{
        prediction: %Prediction{route: %Route{id: "28"}, trip: %Trip{headsign: "Ruggles"}}
      }

      d5 = %Departure{
        prediction: %Prediction{route: %Route{id: "22"}, trip: %Trip{headsign: "Ruggles"}}
      }

      d6 = %Departure{
        schedule: %Schedule{
          route: %Route{id: "22"},
          trip: %Trip{headsign: "Ruggles via Somewhere"}
        }
      }

      d7 = %Departure{
        prediction: %Prediction{
          route: %Route{id: "22"},
          trip: %Trip{headsign: "Ruggles via Somewhere"}
        }
      }

      departures = [d1, d2, d3, d4, d5, d6, d7]
      expected = [[d1, d2], [d3], [d4], [d5], [d6, d7]]
      assert expected == Departures.group_consecutive_departures(departures, bus_shelter_screen)
    end

    test "groups departures and ignores notices", %{bus_shelter_screen: bus_shelter_screen} do
      d1 = %Departure{
        prediction: %Prediction{route: %Route{id: "1"}, trip: %Trip{headsign: "Nubian"}}
      }

      d2 = %Departure{
        prediction: %Prediction{route: %Route{id: "1"}, trip: %Trip{headsign: "Nubian"}}
      }

      d3 = %Departure{
        schedule: %Schedule{route: %Route{id: "22"}, trip: %Trip{headsign: "Ruggles"}}
      }

      n1 = %{text: %FreeTextLine{icon: nil, text: []}}

      departures = [d1, d2, d3, n1]
      expected = [[d1, d2], [d3], [n1]]
      assert expected == Departures.group_consecutive_departures(departures, bus_shelter_screen)
    end
  end

  describe "serialize_route/1" do
    setup do
      %{serializer: &RoutePill.serialize_for_departure/4}
    end

    test "handles default", %{serializer: serializer} do
      departure = %Departure{
        prediction: %Prediction{
          route: %Route{id: "Blue", short_name: "", long_name: "Blue Line", type: :subway}
        }
      }

      assert %{type: :text, text: "BL", color: :blue} ==
               Departures.serialize_route([departure], serializer)

      departure = %Departure{
        prediction: %Prediction{
          route: %Route{id: "Green-B", short_name: "", long_name: "Green Line B", type: :subway}
        }
      }

      assert %{type: :text, text: "GL·B", color: :green} ==
               Departures.serialize_route([departure], serializer)

      departure = %Departure{
        prediction: %Prediction{route: %Route{id: "741", short_name: "SL1", type: :bus}}
      }

      assert %{type: :text, text: "SL1", color: :silver} ==
               Departures.serialize_route([departure], serializer)

      departure = %Departure{
        prediction: %Prediction{route: %Route{id: "1", short_name: "1", type: :bus}}
      }

      assert %{type: :text, text: "1", color: :yellow} ==
               Departures.serialize_route([departure], serializer)
    end

    test "handles slashed routes", %{serializer: serializer} do
      departure = %Departure{
        prediction: %Prediction{route: %Route{id: "214216", short_name: "214/216", type: :bus}}
      }

      assert %{type: :slashed, part1: "214", part2: "216", color: :yellow} ==
               Departures.serialize_route([departure], serializer)
    end

    test "handles rail", %{serializer: serializer} do
      departure = %Departure{
        prediction: %Prediction{route: %Route{id: "CR-Providence", type: :rail}}
      }

      assert %{type: :icon, icon: :rail, color: :purple} ==
               Departures.serialize_route([departure], serializer)
    end

    test "handles ferry", %{serializer: serializer} do
      departure = %Departure{
        prediction: %Prediction{route: %Route{id: "Boat-F1", type: :ferry}}
      }

      assert %{type: :icon, icon: :boat, color: :teal} ==
               Departures.serialize_route([departure], serializer)
    end

    test "handles track numbers", %{serializer: serializer} do
      departure = %Departure{
        prediction: %Prediction{route: %Route{id: "CR-Providence", type: :rail}, track_number: 7}
      }

      assert %{type: :text, text: "TR7", color: :purple} ==
               Departures.serialize_route([departure], serializer)
    end
  end

  describe "serialize_headsign/2" do
    setup do
      %{
        bus_shelter_screen: %Screen{
          app_id: :bus_shelter_v2,
          vendor: :lg_mri,
          device_id: "TEST",
          name: "TEST",
          app_params: nil
        }
      }
    end

    test "handles default", %{bus_shelter_screen: bus_shelter_screen} do
      departure = %Departure{prediction: %Prediction{trip: %Trip{headsign: "Ruggles"}}}

      assert %{headsign: "Ruggles", variation: nil} ==
               Departures.serialize_headsign([departure], bus_shelter_screen)
    end

    test "handles via variations", %{bus_shelter_screen: bus_shelter_screen} do
      departure = %Departure{prediction: %Prediction{trip: %Trip{headsign: "Nubian via Allston"}}}

      assert %{headsign: "Nubian", variation: "via Allston"} ==
               Departures.serialize_headsign([departure], bus_shelter_screen)
    end

    test "handles parenthesized variations", %{bus_shelter_screen: bus_shelter_screen} do
      departure = %Departure{
        prediction: %Prediction{trip: %Trip{headsign: "Beth Israel (Limited Stops)"}}
      }

      assert %{headsign: "Beth Israel", variation: "(Limited Stops)"} ==
               Departures.serialize_headsign([departure], bus_shelter_screen)
    end
  end

  describe "serialize_times_with_crowding/2" do
    setup do
      bus_eink_screen = %Screen{
        app_id: :bus_eink_v2,
        vendor: :gds,
        device_id: "TEST",
        name: "TEST",
        app_params: nil
      }

      bus_shelter_screen = %Screen{
        app_id: :bus_shelter_v2,
        vendor: :lg_mri,
        device_id: "TEST",
        name: "TEST",
        app_params: nil
      }

      %{bus_eink_screen: bus_eink_screen, bus_shelter_screen: bus_shelter_screen}
    end

    test "identifies BRD from vehicle status", %{bus_shelter_screen: screen} do
      serialized_boarding = [%{id: nil, crowding: nil, time: %{text: "BRD", type: :text}}]
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          departure_time: ~U[2020-01-01T00:01:10Z],
          route: %Route{type: :subway},
          vehicle: %Vehicle{current_status: :stopped_at}
        }
      }

      assert serialized_boarding ==
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          departure_time: ~U[2020-01-01T00:02:10Z],
          route: %Route{type: :subway},
          vehicle: %Vehicle{current_status: :stopped_at}
        }
      }

      assert serialized_boarding !=
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          departure_time: ~U[2020-01-01T00:02:10Z],
          route: %Route{type: :subway},
          vehicle: %Vehicle{current_status: :in_transit_to}
        }
      }

      assert serialized_boarding !=
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "identifies BRD from stop type", %{bus_shelter_screen: screen} do
      serialized_boarding = [%{id: nil, crowding: nil, time: %{text: "BRD", type: :text}}]
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: nil,
          departure_time: ~U[2020-01-01T00:00:10Z],
          route: %Route{type: :subway}
        }
      }

      assert serialized_boarding ==
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: nil,
          departure_time: ~U[2020-01-01T00:00:40Z],
          route: %Route{type: :subway}
        }
      }

      assert serialized_boarding !=
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:00:10Z],
          departure_time: ~U[2020-01-01T00:00:10Z],
          route: %Route{type: :subway}
        }
      }

      assert serialized_boarding !=
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "identifies ARR", %{bus_shelter_screen: screen} do
      serialized_arriving = [%{id: nil, crowding: nil, time: %{text: "ARR", type: :text}}]
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:00:10Z],
          departure_time: ~U[2020-01-01T00:00:10Z],
          route: %Route{type: :subway}
        }
      }

      assert serialized_arriving ==
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:00:40Z],
          departure_time: ~U[2020-01-01T00:00:40Z],
          route: %Route{type: :subway}
        }
      }

      assert serialized_arriving !=
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "returns Now on e-Ink screens", %{bus_eink_screen: screen} do
      serialized_now = [%{id: nil, crowding: nil, time: %{text: "Now", type: :text}}]
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:00:50Z],
          departure_time: ~U[2020-01-01T00:00:50Z],
          route: %Route{type: :subway}
        }
      }

      assert serialized_now ==
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:01:10Z],
          departure_time: ~U[2020-01-01T00:01:10Z],
          route: %Route{type: :subway}
        }
      }

      assert serialized_now !=
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "doesn't show minute countdown for rail or ferry", %{bus_shelter_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:20:00Z],
          departure_time: ~U[2020-01-01T00:20:00Z],
          route: %Route{type: :subway}
        }
      }

      assert [%{time: %{type: :minutes}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:20:00Z],
          departure_time: ~U[2020-01-01T00:20:00Z],
          route: %Route{type: :rail}
        }
      }

      assert [%{time: %{type: :timestamp}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:20:00Z],
          departure_time: ~U[2020-01-01T00:20:00Z],
          route: %Route{type: :bus}
        }
      }

      assert [%{time: %{type: :minutes}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:20:00Z],
          departure_time: ~U[2020-01-01T00:20:00Z],
          route: %Route{type: :ferry}
        }
      }

      assert [%{time: %{type: :timestamp}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "correctly serializes timestamps", %{bus_shelter_screen: screen} do
      serialized_timestamp = [
        %{id: nil, crowding: nil, time: %{type: :timestamp, am_pm: :am, hour: 12, minute: 20}}
      ]

      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T05:20:00Z],
          departure_time: ~U[2020-01-01T05:20:00Z],
          route: %Route{type: :subway}
        }
      }

      assert serialized_timestamp ==
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "includes schedule for rail when appropriate", %{bus_shelter_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T02:20:00Z],
          departure_time: ~U[2020-01-01T02:20:00Z],
          route: %Route{type: :rail}
        },
        schedule: %Schedule{
          arrival_time: ~U[2020-01-01T02:15:00Z],
          departure_time: ~U[2020-01-01T02:15:00Z],
          route: %Route{type: :rail}
        }
      }

      assert [
               %{
                 id: nil,
                 crowding: nil,
                 time: %{am_pm: :pm, hour: 9, minute: 20, type: :timestamp},
                 scheduled_time: %{am_pm: :pm, hour: 9, minute: 15, type: :timestamp}
               }
             ] ==
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "doesn't include schedule when the same", %{bus_shelter_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T02:20:00Z],
          departure_time: ~U[2020-01-01T02:20:00Z],
          route: %Route{type: :rail}
        },
        schedule: %Schedule{
          arrival_time: ~U[2020-01-01T02:20:00Z],
          departure_time: ~U[2020-01-01T02:20:00Z],
          route: %Route{type: :rail}
        }
      }

      [result] = Departures.serialize_times_with_crowding([departure], screen, now)
      assert is_nil(Map.get(result, :scheduled_time))
    end

    test "doesn't include schedule when not rail", %{bus_shelter_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T02:20:00Z],
          departure_time: ~U[2020-01-01T02:20:00Z],
          route: %Route{type: :bus}
        },
        schedule: %Schedule{
          arrival_time: ~U[2020-01-01T02:15:00Z],
          departure_time: ~U[2020-01-01T02:15:00Z],
          route: %Route{type: :bus}
        }
      }

      [result] = Departures.serialize_times_with_crowding([departure], screen, now)
      assert is_nil(Map.get(result, :scheduled_time))
    end

    test "doesn't include schedule when prediction is ARR/BRD", %{bus_shelter_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:00:10Z],
          departure_time: ~U[2020-01-01T00:00:10Z],
          route: %Route{type: :rail}
        },
        schedule: %Schedule{
          arrival_time: ~U[2020-01-01T00:05:00Z],
          departure_time: ~U[2020-01-01T00:05:00Z],
          route: %Route{type: :rail}
        }
      }

      [result] = Departures.serialize_times_with_crowding([departure], screen, now)
      assert is_nil(Map.get(result, :scheduled_time))
      assert %{time: %{type: :text}} = result
    end

    test "doesn't include schedule when schedule is nil", %{bus_shelter_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T02:20:00Z],
          departure_time: ~U[2020-01-01T02:20:00Z],
          route: %Route{type: :rail}
        }
      }

      [result] = Departures.serialize_times_with_crowding([departure], screen, now)
      assert is_nil(Map.get(result, :scheduled_time))
    end
  end

  describe "serialize_inline_alerts/1" do
    test "filters all alerts" do
      a1 = %Alert{id: "1", effect: :delay, severity: 4}
      a2 = %Alert{id: "2", effect: :shuttle, severity: 7}
      a3 = %Alert{id: "3", effect: :suspension, severity: 7}
      alerts = [a1, a2, a3]
      departure = %Departure{prediction: %Prediction{alerts: alerts}}

      expected = []

      assert expected == Departures.serialize_inline_alerts([departure])
    end
  end

  describe "slot_names/1" do
    test "returns main_content" do
      instance = %Departures{section_data: []}
      assert [:main_content] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns departures" do
      instance = %Departures{section_data: []}
      assert :departures == WidgetInstance.widget_type(instance)
    end
  end

  describe "audio_serialize/1" do
    test "returns map with sections key" do
      instance = %Departures{}

      assert %{sections: _sections} = WidgetInstance.audio_serialize(instance)
    end
  end

  describe "audio_sort_key/1" do
    test "returns [1]" do
      instance = %Departures{}
      assert [1] == WidgetInstance.audio_sort_key(instance)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns true" do
      instance = %Departures{}
      assert WidgetInstance.audio_valid_candidate?(instance)
    end
  end

  describe "audio_view/1" do
    test "returns DeparturesView" do
      instance = %Departures{}
      assert ScreensWeb.V2.Audio.DeparturesView == WidgetInstance.audio_view(instance)
    end
  end
end
