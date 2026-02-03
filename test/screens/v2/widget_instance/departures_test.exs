defmodule Screens.V2.WidgetInstance.DeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Departures.Departure
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V2.{Departure, WidgetInstance}
  alias Screens.V2.WidgetInstance.Departures
  alias Screens.V2.WidgetInstance.Departures.{HeadwaySection, NoDataSection, NormalSection}
  alias Screens.V2.WidgetInstance.Serializer.RoutePill
  alias Screens.Vehicles.Vehicle
  alias ScreensConfig.Departures.Header
  alias ScreensConfig.Departures.Layout
  alias ScreensConfig.{FreeTextLine, Screen}

  describe "priority/1" do
    test "returns 2" do
      instance = %Departures{sections: []}
      assert [2] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize_section/3" do
    setup do
      %{
        bus_shelter_screen: %Screen{
          app_id: :bus_shelter_v2,
          vendor: :lg_mri,
          device_id: "TEST",
          name: "TEST",
          app_params: nil
        },
        now: ~U[2020-01-01T00:00:00Z]
      }
    end

    test "returns serialized normal_section", %{bus_shelter_screen: bus_shelter_screen, now: now} do
      section = %NormalSection{rows: [], layout: %Layout{}, header: %Header{}}

      assert %{type: :normal_section, rows: []} =
               Departures.serialize_section(section, bus_shelter_screen, now)
    end

    test "returns serialized normal_section with a header if a header exists", %{
      bus_shelter_screen: bus_shelter_screen,
      now: now
    } do
      section = %NormalSection{
        rows: [],
        layout: %Layout{},
        header: %Header{
          title: "Simple Test Header",
          arrow: :n,
          read_as: "Special read-as text"
        }
      }

      assert %{
               type: :normal_section,
               header: %{title: "Simple Test Header", arrow: :n, read_as: "Special read-as text"}
             } = Departures.serialize_section(section, bus_shelter_screen, now)
    end

    test "returns serialized normal_section with notice", %{
      bus_shelter_screen: bus_shelter_screen,
      now: now
    } do
      section = %NormalSection{
        rows: [%FreeTextLine{icon: nil, text: []}],
        layout: %Layout{},
        header: %Header{}
      }

      assert %{type: :normal_section, rows: [%{type: :notice_row, text: %{icon: nil, text: []}}]} =
               Departures.serialize_section(section, bus_shelter_screen, now)
    end
  end

  describe "serialize_section/4" do
    setup do
      %{
        dup_screen: %Screen{
          app_id: :dup_v2,
          vendor: :outfront,
          device_id: "TEST",
          name: "TEST",
          app_params: nil
        },
        bus_shelter_screen: %Screen{
          app_id: :bus_shelter_v2,
          vendor: :lg_mri,
          device_id: "TEST",
          name: "TEST",
          app_params: nil
        },
        now: ~U[2020-01-01T00:00:00Z]
      }
    end

    test "returns serialized normal_section for section with row with no scheduled time", %{
      dup_screen: dup_screen,
      now: now
    } do
      section = %NormalSection{
        layout: %Layout{},
        header: %Header{},
        rows: [
          %Departure{
            schedule:
              struct(Schedule,
                arrival_time: nil,
                departure_time: nil,
                route: %Screens.Routes.Route{
                  id: "Orange",
                  type: :subway,
                  long_name: "Orange Line"
                },
                stop: %Stop{id: "70015", name: "Back Bay"},
                stop_headsign: "Oak Grove"
              )
          }
        ]
      }

      assert %{
               rows: [
                 %{
                   headsign: %{headsign: "Oak Grove"},
                   # MD5 hash when the schedule ID is nil. Won't change unless ID does.
                   id: "1B2M2Y8AsgTpgAmY7PhCfg==",
                   route: %{color: :orange, text: "OL", type: :text},
                   times_with_crowding: [%{id: nil, crowding: nil, time: %{type: :overnight}}],
                   type: :departure_row
                 }
               ],
               type: :normal_section,
               grouping_type: :time
             } =
               Departures.serialize_section(section, dup_screen, now, true)
    end

    test "returns serialized headway_section for one configured section", %{
      dup_screen: dup_screen,
      now: now
    } do
      section = %HeadwaySection{route: "Red", time_range: {1, 2}, headsign: "Test"}

      expected_text = %{
        icon: "subway-negative-black",
        text: [
          %{color: :red, text: "RED LINE"},
          %{special: :break},
          "Test trains every",
          %{format: :bold, text: "1-2"},
          "minutes"
        ]
      }

      assert %{type: :headway_section, text: expected_text, layout: :full_screen} ==
               Departures.serialize_section(section, dup_screen, now, true)
    end

    test "returns serialized headway_section for one configured section with Ashmont/Braintree headsign",
         %{
           dup_screen: dup_screen,
           now: now
         } do
      section = %HeadwaySection{route: "Red", time_range: {1, 2}, headsign: "Ashmont/Braintree"}

      expected_text = %{
        icon: "subway-negative-black",
        text: [
          %{color: :red, text: "RED LINE"},
          %{special: :break},
          "Ashmont/Braintree trains every",
          %{format: :bold, text: "1-2m"}
        ]
      }

      assert %{type: :headway_section, text: expected_text, layout: :full_screen} ==
               Departures.serialize_section(section, dup_screen, now, true)
    end

    test "returns serialized headway_section for multiple configured sections", %{
      dup_screen: dup_screen,
      now: now
    } do
      section = %HeadwaySection{route: "Red", time_range: {1, 2}, headsign: nil}

      expected_text = %{
        icon: :red,
        text: ["every", %{format: :bold, text: "1-2"}, "minutes"]
      }

      assert %{type: :headway_section, text: expected_text, layout: :row} ==
               Departures.serialize_section(section, dup_screen, now, false)
    end

    test "returns serialized headway_section for multiple configured sections with headsign", %{
      dup_screen: dup_screen,
      now: now
    } do
      section = %HeadwaySection{route: "Red", time_range: {12, 15}, headsign: "Alewife"}

      expected_text = %{
        icon: :red,
        text: [%{format: :bold, text: "Alewife"}, %{format: :small, text: "every 12-15m"}]
      }

      assert %{type: :headway_section, text: expected_text, layout: :row} ==
               Departures.serialize_section(section, dup_screen, now, false)
    end

    test "returns serialized no_data_section for subway/light rail", %{
      dup_screen: dup_screen,
      now: now
    } do
      section = %NoDataSection{route: %{id: "Orange", type: :subway}}

      expected_text = %{
        icon: :orange,
        text: ["Updates unavailable"]
      }

      assert %{type: :no_data_section, text: expected_text} ==
               Departures.serialize_section(section, dup_screen, now, true)

      section = %NoDataSection{route: %{id: "Green", type: :light_rail}}

      expected_text = %{
        icon: :green,
        text: ["Updates unavailable"]
      }

      assert %{type: :no_data_section, text: expected_text} ==
               Departures.serialize_section(section, dup_screen, now, true)
    end

    test "returns serialized no_data_section for bus", %{
      dup_screen: dup_screen,
      now: now
    } do
      section = %NoDataSection{route: %{id: "555", type: :bus}}

      expected_text = %{
        icon: :bus,
        text: ["Updates unavailable"]
      }

      assert %{type: :no_data_section, text: expected_text} ==
               Departures.serialize_section(section, dup_screen, now, true)
    end

    test "returns serialized no_data_section for SL", %{
      dup_screen: dup_screen,
      now: now
    } do
      section = %NoDataSection{route: %{short_name: "SL1", type: :bus}}

      expected_text = %{
        icon: :silver,
        text: ["Updates unavailable"]
      }

      assert %{type: :no_data_section, text: expected_text} ==
               Departures.serialize_section(section, dup_screen, now, true)
    end

    test "returns serialized no_data_section for CR", %{
      dup_screen: dup_screen,
      now: now
    } do
      section = %NoDataSection{route: %{id: "CR-Test", type: :rail}}

      expected_text = %{
        icon: :cr,
        text: ["Updates unavailable"]
      }

      assert %{type: :no_data_section, text: expected_text} ==
               Departures.serialize_section(section, dup_screen, now, true)
    end

    test "serializes sections with destination grouping", %{
      bus_shelter_screen: bus_shelter_screen,
      now: now
    } do
      rows = [
        %Departure{
          prediction: %Prediction{
            departure_time: ~U[2020-01-01T00:01:10Z],
            route: %Route{id: "Green-E", type: :subway},
            trip: %Trip{headsign: "Medford/Tufts", direction_id: 1},
            stop: %Stop{}
          }
        },
        %Departure{
          prediction: %Prediction{
            departure_time: ~U[2020-01-01T00:01:10Z],
            route: %Route{id: "Green-D"},
            trip: %Trip{headsign: "Government Center", direction_id: 1},
            stop: %Stop{}
          }
        },
        %Departure{
          prediction: %Prediction{
            departure_time: ~U[2020-01-01T00:01:10Z],
            route: %Route{id: "Green-C", type: :subway},
            trip: %Trip{headsign: "Cleveland Circle", direction_id: 0},
            stop: %Stop{}
          }
        },
        %Departure{
          prediction: %Prediction{
            departure_time: ~U[2020-01-01T00:01:10Z],
            route: %Route{id: "Green-C", type: :subway},
            trip: %Trip{headsign: "Cleveland Circle", direction_id: 0},
            stop: %Stop{}
          }
        },
        %Departure{
          prediction: %Prediction{
            departure_time: ~U[2020-01-01T00:01:10Z],
            route: %Route{id: "Green-D", type: :subway},
            trip: %Trip{headsign: "Riverside", direction_id: 0},
            stop: %Stop{}
          }
        }
      ]

      section = %NormalSection{
        rows: rows,
        layout: %Layout{},
        header: %Header{title: "Section Header"},
        grouping_type: :destination
      }

      assert %{
               type: :normal_section,
               grouping_type: :destination,
               layout: %{
                 max: nil,
                 min: 2,
                 base: 4,
                 include_later: false
               },
               rows: [
                 %{headsign: %{headsign: "Medford/Tufts"}},
                 %{headsign: %{headsign: "Government Center"}},
                 %{headsign: %{headsign: "Cleveland Circle"}},
                 %{headsign: %{headsign: "Riverside"}}
               ]
             } =
               Departures.serialize_section(section, bus_shelter_screen, now, false)
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
        },
        dup_screen: %Screen{
          app_id: :dup_v2,
          vendor: :outfront,
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

      n1 = %FreeTextLine{icon: nil, text: []}

      departures = [d1, d2, d3, n1]
      expected = [[d1, d2], [d3], [n1]]
      assert expected == Departures.group_consecutive_departures(departures, bus_shelter_screen)
    end

    test "keeps departures ungrouped for DUPs", %{dup_screen: dup_screen} do
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
        schedule: %Schedule{route: %Route{id: "22"}, trip: %Trip{headsign: "Ruggles"}}
      }

      departures = [d1, d2, d3, d4]
      expected = [[d1], [d2], [d3], [d4]]
      assert expected == Departures.group_consecutive_departures(departures, dup_screen)
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

      assert %{type: :icon, icon: :rail, color: :purple, route_abbrev: "PVD"} ==
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

      assert %{type: :text, text: "TR7", color: :purple, route_abbrev: "PVD"} ==
               Departures.serialize_route([departure], serializer)
    end
  end

  describe "group_by_unique_destination/1" do
    test "groups by unique destinations on headsign and direction_id" do
      d1 = %Departure{
        schedule: %Schedule{
          route: %Route{id: "22"},
          trip: %Trip{headsign: "Government Center", direction_id: 1}
        }
      }

      d2 = %Departure{
        prediction: %Prediction{
          route: %Route{id: "28"},
          trip: %Trip{headsign: "Medford/Tufts", direction_id: 1}
        }
      }

      d3 = %Departure{
        prediction: %Prediction{
          route: %Route{id: "22"},
          trip: %Trip{headsign: "Government Center", direction_id: 1}
        }
      }

      d4 = %Departure{
        prediction: %Prediction{
          route: %Route{id: "1"},
          trip: %Trip{headsign: "Cleveland Circle", direction_id: 0}
        }
      }

      d5 = %Departure{
        schedule: %Schedule{
          route: %Route{id: "22"},
          trip: %Trip{headsign: "Riverside", direction_id: 0}
        }
      }

      d6 = %Departure{
        prediction: %Prediction{
          route: %Route{id: "1"},
          trip: %Trip{headsign: "Cleveland Circle", direction_id: 0}
        }
      }

      d7 = %Departure{
        prediction: %Prediction{
          route: %Route{id: "22"},
          trip: %Trip{headsign: "Riverside", direction_id: 0}
        }
      }

      departures = [d1, d2, d3, d4, d5, d6, d7]
      expected = [[d1], [d2], [d4], [d5]]
      assert expected == Departures.group_by_unique_destination(departures)
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
        },
        dup_screen: %Screen{
          app_id: :dup_v2,
          vendor: :outfront,
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

    test "handles DUPs", %{dup_screen: dup_screen} do
      departure = %Departure{
        prediction: %Prediction{trip: %Trip{headsign: "Test 1"}}
      }

      assert %{headsign: "T1"} ==
               Departures.serialize_headsign([departure], dup_screen)

      departure = %Departure{
        prediction: %Prediction{trip: %Trip{headsign: "Test 2"}}
      }

      assert %{headsign: "Test 2"} ==
               Departures.serialize_headsign([departure], dup_screen)
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

      dup_screen = %Screen{
        app_id: :dup_v2,
        vendor: :outfront,
        device_id: "TEST",
        name: "TEST",
        app_params: nil
      }

      %{
        bus_eink_screen: bus_eink_screen,
        bus_shelter_screen: bus_shelter_screen,
        dup_screen: dup_screen
      }
    end

    test "identifies BRD from vehicle status", %{bus_shelter_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          departure_time: ~U[2020-01-01T00:01:10Z],
          route: %Route{type: :subway},
          vehicle: %Vehicle{current_status: :stopped_at, stop_id: "stop-b"},
          stop: %Stop{id: "stop-b"}
        }
      }

      assert [%{time: %{type: :text, text: "BRD"}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          departure_time: ~U[2020-01-01T00:01:10Z],
          route: %Route{type: :subway},
          vehicle: %Vehicle{current_status: :stopped_at, stop_id: "stop-a"},
          stop: %Stop{id: "stop-b"}
        }
      }

      assert [%{time: %{type: :minutes, minutes: 1}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          departure_time: ~U[2020-01-01T00:02:10Z],
          route: %Route{type: :subway},
          vehicle: %Vehicle{current_status: :stopped_at},
          stop: %Stop{}
        }
      }

      assert [%{time: %{type: :minutes, minutes: 2}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          departure_time: ~U[2020-01-01T00:02:10Z],
          route: %Route{type: :subway},
          vehicle: %Vehicle{current_status: :in_transit_to},
          stop: %Stop{}
        }
      }

      assert [%{time: %{type: :minutes, minutes: 2}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "identifies BRD from stop type", %{bus_shelter_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: nil,
          departure_time: ~U[2020-01-01T00:00:10Z],
          route: %Route{type: :subway},
          stop: %Stop{}
        }
      }

      assert [%{time: %{type: :text, text: "BRD"}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: nil,
          departure_time: ~U[2020-01-01T00:00:40Z],
          route: %Route{type: :subway},
          stop: %Stop{}
        }
      }

      assert [%{time: %{type: :minutes, minutes: 1}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:00:10Z],
          departure_time: ~U[2020-01-01T00:00:10Z],
          route: %Route{type: :subway},
          stop: %Stop{}
        }
      }

      assert [%{time: %{type: :text, text: "ARR"}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "identifies ARR", %{bus_shelter_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:00:10Z],
          departure_time: ~U[2020-01-01T00:00:10Z],
          route: %Route{type: :subway},
          stop: %Stop{}
        }
      }

      assert [%{time: %{type: :text, text: "ARR"}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:00:40Z],
          departure_time: ~U[2020-01-01T00:00:40Z],
          route: %Route{type: :subway},
          stop: %Stop{}
        }
      }

      assert [%{time: %{type: :minutes, minutes: 1}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "returns Now on e-Ink screens", %{bus_eink_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]
      departure_time = ~U[2020-01-01T00:00:50Z]

      now_timestamp = %{
        id: nil,
        crowding: nil,
        time: %{text: "Now", type: :text},
        time_in_epoch: DateTime.to_unix(departure_time)
      }

      serialized_now = [now_timestamp]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: departure_time,
          departure_time: departure_time,
          route: %Route{type: :subway}
        }
      }

      assert serialized_now ==
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure_time = ~U[2020-01-01T00:01:10Z]
      serialized_now = [%{now_timestamp | time_in_epoch: DateTime.to_unix(departure_time)}]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: departure_time,
          departure_time: departure_time,
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
          route: %Route{type: :subway},
          stop: %Stop{}
        }
      }

      assert [%{time: %{type: :minutes}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:20:00Z],
          departure_time: ~U[2020-01-01T00:20:00Z],
          route: %Route{type: :rail},
          stop: %Stop{}
        }
      }

      assert [%{time: %{type: :timestamp}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:20:00Z],
          departure_time: ~U[2020-01-01T00:20:00Z],
          route: %Route{type: :bus},
          stop: %Stop{}
        }
      }

      assert [%{time: %{type: :minutes}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T00:20:00Z],
          departure_time: ~U[2020-01-01T00:20:00Z],
          route: %Route{type: :ferry},
          stop: %Stop{}
        }
      }

      assert [%{time: %{type: :timestamp}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "does not show BRD or ARR for scheduled departures", %{dup_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        schedule: %Schedule{
          arrival_time: nil,
          departure_time: ~U[2020-01-01T00:00:15Z],
          route: %Route{type: :ferry},
          stop: %Stop{}
        }
      }

      assert [%{time: %{type: :timestamp, am_pm: nil, hour: 7, minute: 0}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "returns only scheduled time for skipped/cancelled departures", %{dup_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          departure_time: ~U[2020-01-01T00:00:15Z],
          schedule_relationship: :cancelled,
          route: %Route{type: :rail}
        },
        schedule: %Schedule{
          departure_time: ~U[2020-01-01T00:00:15Z],
          route: %Route{type: :rail}
        }
      }

      assert [%{time: nil, scheduled_time: %{type: :timestamp}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)

      departure = put_in(departure.prediction.schedule_relationship, :skipped)

      assert [%{time: nil, scheduled_time: %{type: :timestamp}}] =
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "correctly serializes timestamps", %{bus_shelter_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T05:20:00Z],
          departure_time: ~U[2020-01-01T05:20:00Z],
          route: %Route{type: :subway},
          stop: %Stop{}
        }
      }

      assert [
               %{
                 id: nil,
                 crowding: nil,
                 time: %{type: :timestamp, am_pm: nil, hour: 12, minute: 20}
               }
             ] =
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "includes schedule for rail when appropriate", %{bus_shelter_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T02:20:00Z],
          departure_time: ~U[2020-01-01T02:20:00Z],
          route: %Route{type: :rail},
          stop: %Stop{}
        },
        schedule: %Schedule{
          arrival_time: ~U[2020-01-01T02:15:00Z],
          departure_time: ~U[2020-01-01T02:15:00Z],
          route: %Route{type: :rail},
          stop: %Stop{}
        }
      }

      assert [
               %{
                 id: nil,
                 crowding: nil,
                 time: %{am_pm: nil, hour: 9, minute: 20, type: :timestamp},
                 scheduled_time: %{am_pm: nil, hour: 9, minute: 15, type: :timestamp}
               }
             ] =
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "doesn't include schedule when the same", %{bus_shelter_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T02:20:00Z],
          departure_time: ~U[2020-01-01T02:20:00Z],
          route: %Route{type: :rail},
          stop: %Stop{}
        },
        schedule: %Schedule{
          arrival_time: ~U[2020-01-01T02:20:00Z],
          departure_time: ~U[2020-01-01T02:20:00Z],
          route: %Route{type: :rail},
          stop: %Stop{}
        }
      }

      assert [%{scheduled_time: nil}] =
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "doesn't include schedule when not rail", %{bus_shelter_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T02:20:00Z],
          departure_time: ~U[2020-01-01T02:20:00Z],
          route: %Route{type: :bus},
          stop: %Stop{}
        },
        schedule: %Schedule{
          arrival_time: ~U[2020-01-01T02:15:00Z],
          departure_time: ~U[2020-01-01T02:15:00Z],
          route: %Route{type: :bus},
          stop: %Stop{}
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
          route: %Route{type: :bus},
          stop: %Stop{}
        },
        schedule: %Schedule{
          arrival_time: ~U[2020-01-01T00:05:00Z],
          departure_time: ~U[2020-01-01T00:05:00Z],
          route: %Route{type: :bus},
          stop: %Stop{}
        }
      }

      assert [%{time: %{type: :text}, scheduled_time: nil}] =
               Departures.serialize_times_with_crowding([departure], screen, now)
    end

    test "doesn't include schedule when schedule is nil", %{bus_shelter_screen: screen} do
      now = ~U[2020-01-01T00:00:00Z]

      departure = %Departure{
        prediction: %Prediction{
          arrival_time: ~U[2020-01-01T02:20:00Z],
          departure_time: ~U[2020-01-01T02:20:00Z],
          route: %Route{type: :rail},
          stop: %Stop{}
        }
      }

      [result] = Departures.serialize_times_with_crowding([departure], screen, now)
      assert is_nil(Map.get(result, :scheduled_time))
    end
  end

  describe "slot_names/1" do
    test "returns main_content" do
      instance = %Departures{sections: []}
      assert [:main_content] == WidgetInstance.slot_names(instance)
    end
  end

  describe "widget_type/1" do
    test "returns departures" do
      instance = %Departures{sections: []}
      assert :departures == WidgetInstance.widget_type(instance)
    end
  end

  describe "audio_serialize/1" do
    test "returns map with sections key" do
      instance = %Departures{}

      assert %{sections: _sections} = WidgetInstance.audio_serialize(instance)
    end
  end

  describe "audio_serialize_section/3" do
    @now ~U[2020-01-01T00:00:00Z]

    @prediction %Prediction{
      arrival_time: ~U[2020-01-01T09:00:00Z],
      route: %Route{id: "Red"},
      trip: %Trip{headsign: "Test"},
      stop: %Stop{id: "place-test"}
    }

    test "can serialize a :normal_section" do
      screen = struct(Screen, %{app_id: :gl_eink_v2})

      section = %NormalSection{
        rows: [],
        header: %Header{title: "Section Header", subtitle: nil},
        layout: %Layout{}
      }

      assert %{
               type: :normal_section,
               departure_groups: [],
               header: "Section Header"
             } = Departures.audio_serialize_section(section, screen, @now)
    end

    test "uses the `read_as` header property if available" do
      screen = struct(Screen, %{app_id: :gl_eink_v2})

      section = %NormalSection{
        rows: [],
        header: %Header{
          title: "Section Header",
          read_as: "A special audio-only value",
          subtitle: "Section Subtitle"
        },
        layout: %Layout{}
      }

      assert %{header: "A special audio-only value"} =
               Departures.audio_serialize_section(section, screen, @now)
    end

    test "includes the `subtitle` header property if available, filtering out markdown" do
      screen = struct(Screen, %{app_id: :gl_eink_v2})

      section = %NormalSection{
        rows: [],
        header: %Header{title: "Section Header", subtitle: "Section **Subtitle**"},
        layout: %Layout{}
      }

      assert %{header: "Section Header. Section Subtitle"} =
               Departures.audio_serialize_section(section, screen, @now)
    end

    test "respects the configured layout's maximum number of departures" do
      screen = struct(Screen, %{app_id: :bus_shelter_v2})

      max_limited_section = %NormalSection{
        rows: [
          %Departure{prediction: @prediction},
          %Departure{prediction: @prediction},
          %Departure{prediction: %{@prediction | route: %Route{id: "1"}}},
          %Departure{prediction: %{@prediction | route: %Route{id: "2"}}}
        ],
        header: %Header{},
        layout: %Layout{max: 3}
      }

      base_limited_section = %NormalSection{max_limited_section | layout: %Layout{base: 2}}

      assert %{
               departure_groups: [
                 {:normal, %{times_with_crowding: [_one, _two]}},
                 {:normal, %{times_with_crowding: [_three]}}
               ]
             } = Departures.audio_serialize_section(max_limited_section, screen, @now)

      assert %{departure_groups: [{:normal, %{times_with_crowding: [_one, _two]}}]} =
               Departures.audio_serialize_section(base_limited_section, screen, @now)
    end

    test "always limits to one departure per group in destination grouping mode" do
      screen = struct(Screen, %{app_id: :bus_shelter_v2})

      section = %NormalSection{
        rows: [
          %Departure{
            prediction: %{
              @prediction
              | arrival_time: ~U[2020-01-01T09:00:00Z],
                route: %Route{id: "1"}
            }
          },
          %Departure{
            prediction: %{
              @prediction
              | arrival_time: ~U[2020-01-01T09:10:00Z],
                route: %Route{id: "1"}
            }
          },
          %Departure{
            prediction: %{
              @prediction
              | arrival_time: ~U[2020-01-01T09:00:00Z],
                route: %Route{id: "2"}
            }
          },
          %Departure{
            prediction: %{
              @prediction
              | arrival_time: ~U[2020-01-01T09:15:00Z],
                route: %Route{id: "2"}
            }
          }
        ],
        grouping_type: :destination,
        header: %Header{},
        layout: %Layout{}
      }

      assert %{
               departure_groups: [
                 {:normal, %{route: %{id: "1"}, times_with_crowding: [_]}},
                 {:normal, %{route: %{id: "2"}, times_with_crowding: [_]}}
               ]
             } = Departures.audio_serialize_section(section, screen, @now)
    end

    test "busway_v2 return 1 departure time if first departure is > 2 minutes away" do
      screen = struct(Screen, %{app_id: :busway_v2})

      section = %NormalSection{
        rows: [
          %Departure{
            prediction: %Prediction{
              arrival_time: ~U[2020-01-01T00:05:00Z],
              route: %Route{type: :subway},
              trip: %Trip{headsign: "Test"},
              stop: %Stop{id: "place-test"}
            }
          },
          %Departure{
            prediction: %Prediction{
              arrival_time: ~U[2020-01-01T02:01:00Z],
              route: %Route{type: :subway},
              trip: %Trip{headsign: "Test"},
              stop: %Stop{id: "place-test"}
            }
          }
        ],
        header: %Header{},
        layout: %Layout{}
      }

      assert %{
               departure_groups: [
                 {:normal,
                  %{
                    id: "1B2M2Y8AsgTpgAmY7PhCfg==",
                    type: :departure_row,
                    headsign: %{headsign: "Test", variation: nil},
                    route: %{track_number: nil, vehicle_type: :train, route_text: nil},
                    times_with_crowding: [
                      %{id: nil, time: %{type: :minutes, minutes: 5}, crowding: nil}
                    ]
                  }}
               ]
             } = Departures.audio_serialize_section(section, screen, @now)
    end

    test "busway_v2 return 2 departure times if first departure is <= 2 minutes away" do
      screen = struct(Screen, %{app_id: :busway_v2})

      section = %NormalSection{
        rows: [
          %Departure{
            prediction: %Prediction{
              arrival_time: ~U[2020-01-01T00:01:00Z],
              route: %Route{type: :subway},
              trip: %Trip{headsign: "Test"},
              stop: %Stop{id: "place-test"}
            }
          },
          %Departure{
            prediction: %Prediction{
              arrival_time: ~U[2020-01-01T00:02:00Z],
              route: %Route{type: :subway},
              trip: %Trip{headsign: "Test"},
              stop: %Stop{id: "place-test"}
            }
          }
        ],
        header: %Header{},
        layout: %Layout{}
      }

      assert %{
               departure_groups: [
                 {:normal,
                  %{
                    id: "1B2M2Y8AsgTpgAmY7PhCfg==",
                    type: :departure_row,
                    headsign: %{headsign: "Test", variation: nil},
                    route: %{track_number: nil, vehicle_type: :train, route_text: nil},
                    times_with_crowding: [
                      %{id: nil, time: %{type: :minutes, minutes: 1}, crowding: nil},
                      %{id: nil, time: %{type: :minutes, minutes: 2}, crowding: nil}
                    ]
                  }}
               ]
             } = Departures.audio_serialize_section(section, screen, @now)
    end

    test "non-busway screen types always use a max of 2 departures" do
      screen = struct(Screen, %{app_id: :gl_eink_v2})

      section = %NormalSection{
        rows: [
          %Departure{
            prediction: %Prediction{
              arrival_time: ~U[2020-01-01T00:05:00Z],
              route: %Route{type: :subway},
              trip: %Trip{headsign: "Test"},
              stop: %Stop{id: "place-test"}
            }
          },
          %Departure{
            prediction: %Prediction{
              arrival_time: ~U[2020-01-01T00:06:00Z],
              route: %Route{type: :subway},
              trip: %Trip{headsign: "Test"},
              stop: %Stop{id: "place-test"}
            }
          },
          %Departure{
            prediction: %Prediction{
              arrival_time: ~U[2020-01-01T00:07:00Z],
              route: %Route{type: :subway},
              trip: %Trip{headsign: "Test"},
              stop: %Stop{id: "place-test"}
            }
          }
        ],
        header: %Header{},
        layout: %Layout{}
      }

      assert %{
               departure_groups: [
                 {:normal,
                  %{
                    type: :departure_row,
                    headsign: %{headsign: "Test", variation: nil},
                    route: %{track_number: nil, vehicle_type: :train, route_text: nil},
                    times_with_crowding: [
                      %{id: nil, time: %{type: :minutes, minutes: 5}, crowding: nil},
                      %{id: nil, time: %{type: :minutes, minutes: 6}, crowding: nil}
                    ]
                  }}
               ]
             } = Departures.audio_serialize_section(section, screen, @now)
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
