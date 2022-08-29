defmodule Screens.V2.WidgetInstance.CRDeparturesTest do
  use ExUnit.Case, async: true

  # alias Screens.Alerts.Alert
  # alias Screens.Config.Dup.Override.FreeTextLine
  # alias Screens.Config.Screen
  alias Screens.Predictions.Prediction
  # alias Screens.Routes.Route
  # alias Screens.Schedules.Schedule
  alias Screens.Trips.Trip
  # alias Screens.Vehicles.Vehicle
  alias Screens.V2.{Departure, WidgetInstance}
  alias Screens.V2.WidgetInstance.CRDepartures, as: CRDeparturesWidget
  # alias Screens.V2.WidgetInstance.Serializer.RoutePill

  describe "priority/1" do
    test "returns 2" do
      instance = %CRDeparturesWidget{config: %{priority: [1]}}
      assert [1] == WidgetInstance.priority(instance)
    end
  end

  describe "serialize_headsign/1" do
    test "handles default" do
      departure = %Departure{prediction: %Prediction{trip: %Trip{headsign: "Ruggles"}}}

      assert %{headsign: "Ruggles", station_service_list: []} ==
               CRDeparturesWidget.serialize_headsign(departure, "Nowhere")
    end

    test "handles via variations" do
      departure = %Departure{
        prediction: %Prediction{trip: %Trip{headsign: "South Station via Back Bay"}}
      }

      assert %{
               headsign: "South Station",
               station_service_list: [
                 %{name: "Ruggles", service: true},
                 %{name: "Back Bay", service: true}
               ]
             } ==
               CRDeparturesWidget.serialize_headsign(departure, "Back Bay")
    end

    test "handles parenthesized variations" do
      departure = %Departure{
        prediction: %Prediction{trip: %Trip{headsign: "Beth Israel (Limited Stops)"}}
      }

      assert %{headsign: "Beth Israel", station_service_list: []} ==
               CRDeparturesWidget.serialize_headsign(departure, "Somewhere")
    end
  end

  # describe "serialize_times_with_crowding/2" do
  #   setup do
  #     bus_eink_screen = %Screen{
  #       app_id: :bus_eink_v2,
  #       vendor: :gds,
  #       device_id: "TEST",
  #       name: "TEST",
  #       app_params: nil
  #     }

  #     bus_shelter_screen = %Screen{
  #       app_id: :bus_shelter_v2,
  #       vendor: :lg_mri,
  #       device_id: "TEST",
  #       name: "TEST",
  #       app_params: nil
  #     }

  #     %{bus_eink_screen: bus_eink_screen, bus_shelter_screen: bus_shelter_screen}
  #   end

  #   test "identifies BRD from vehicle status", %{bus_shelter_screen: screen} do
  #     serialized_boarding = [%{id: nil, crowding: nil, time: %{text: "BRD", type: :text}}]
  #     now = ~U[2020-01-01T00:00:00Z]

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         departure_time: ~U[2020-01-01T00:01:10Z],
  #         route: %Route{type: :subway},
  #         vehicle: %Vehicle{current_status: :stopped_at}
  #       }
  #     }

  #     assert serialized_boarding ==
  #              Departures.serialize_times_with_crowding([departure], screen, now)

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         departure_time: ~U[2020-01-01T00:02:10Z],
  #         route: %Route{type: :subway},
  #         vehicle: %Vehicle{current_status: :stopped_at}
  #       }
  #     }

  #     assert serialized_boarding !=
  #              Departures.serialize_times_with_crowding([departure], screen, now)

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         departure_time: ~U[2020-01-01T00:02:10Z],
  #         route: %Route{type: :subway},
  #         vehicle: %Vehicle{current_status: :in_transit_to}
  #       }
  #     }

  #     assert serialized_boarding !=
  #              Departures.serialize_times_with_crowding([departure], screen, now)
  #   end

  #   test "identifies BRD from stop type", %{bus_shelter_screen: screen} do
  #     serialized_boarding = [%{id: nil, crowding: nil, time: %{text: "BRD", type: :text}}]
  #     now = ~U[2020-01-01T00:00:00Z]

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: nil,
  #         departure_time: ~U[2020-01-01T00:00:10Z],
  #         route: %Route{type: :subway}
  #       }
  #     }

  #     assert serialized_boarding ==
  #              Departures.serialize_times_with_crowding([departure], screen, now)

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: nil,
  #         departure_time: ~U[2020-01-01T00:00:40Z],
  #         route: %Route{type: :subway}
  #       }
  #     }

  #     assert serialized_boarding !=
  #              Departures.serialize_times_with_crowding([departure], screen, now)

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: ~U[2020-01-01T00:00:10Z],
  #         departure_time: ~U[2020-01-01T00:00:10Z],
  #         route: %Route{type: :subway}
  #       }
  #     }

  #     assert serialized_boarding !=
  #              Departures.serialize_times_with_crowding([departure], screen, now)
  #   end

  #   test "identifies ARR", %{bus_shelter_screen: screen} do
  #     serialized_arriving = [%{id: nil, crowding: nil, time: %{text: "ARR", type: :text}}]
  #     now = ~U[2020-01-01T00:00:00Z]

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: ~U[2020-01-01T00:00:10Z],
  #         departure_time: ~U[2020-01-01T00:00:10Z],
  #         route: %Route{type: :subway}
  #       }
  #     }

  #     assert serialized_arriving ==
  #              Departures.serialize_times_with_crowding([departure], screen, now)

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: ~U[2020-01-01T00:00:40Z],
  #         departure_time: ~U[2020-01-01T00:00:40Z],
  #         route: %Route{type: :subway}
  #       }
  #     }

  #     assert serialized_arriving !=
  #              Departures.serialize_times_with_crowding([departure], screen, now)
  #   end

  #   test "returns Now on e-Ink screens", %{bus_eink_screen: screen} do
  #     serialized_now = [%{id: nil, crowding: nil, time: %{text: "Now", type: :text}}]
  #     now = ~U[2020-01-01T00:00:00Z]

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: ~U[2020-01-01T00:00:50Z],
  #         departure_time: ~U[2020-01-01T00:00:50Z],
  #         route: %Route{type: :subway}
  #       }
  #     }

  #     assert serialized_now ==
  #              Departures.serialize_times_with_crowding([departure], screen, now)

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: ~U[2020-01-01T00:01:10Z],
  #         departure_time: ~U[2020-01-01T00:01:10Z],
  #         route: %Route{type: :subway}
  #       }
  #     }

  #     assert serialized_now !=
  #              Departures.serialize_times_with_crowding([departure], screen, now)
  #   end

  #   test "doesn't show minute countdown for rail or ferry", %{bus_shelter_screen: screen} do
  #     now = ~U[2020-01-01T00:00:00Z]

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: ~U[2020-01-01T00:20:00Z],
  #         departure_time: ~U[2020-01-01T00:20:00Z],
  #         route: %Route{type: :subway}
  #       }
  #     }

  #     assert [%{time: %{type: :minutes}}] =
  #              Departures.serialize_times_with_crowding([departure], screen, now)

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: ~U[2020-01-01T00:20:00Z],
  #         departure_time: ~U[2020-01-01T00:20:00Z],
  #         route: %Route{type: :rail}
  #       }
  #     }

  #     assert [%{time: %{type: :timestamp}}] =
  #              Departures.serialize_times_with_crowding([departure], screen, now)

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: ~U[2020-01-01T00:20:00Z],
  #         departure_time: ~U[2020-01-01T00:20:00Z],
  #         route: %Route{type: :bus}
  #       }
  #     }

  #     assert [%{time: %{type: :minutes}}] =
  #              Departures.serialize_times_with_crowding([departure], screen, now)

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: ~U[2020-01-01T00:20:00Z],
  #         departure_time: ~U[2020-01-01T00:20:00Z],
  #         route: %Route{type: :ferry}
  #       }
  #     }

  #     assert [%{time: %{type: :timestamp}}] =
  #              Departures.serialize_times_with_crowding([departure], screen, now)
  #   end

  #   test "correctly serializes timestamps", %{bus_shelter_screen: screen} do
  #     serialized_timestamp = [
  #       %{id: nil, crowding: nil, time: %{type: :timestamp, am_pm: :am, hour: 12, minute: 20}}
  #     ]

  #     now = ~U[2020-01-01T00:00:00Z]

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: ~U[2020-01-01T05:20:00Z],
  #         departure_time: ~U[2020-01-01T05:20:00Z],
  #         route: %Route{type: :subway}
  #       }
  #     }

  #     assert serialized_timestamp ==
  #              Departures.serialize_times_with_crowding([departure], screen, now)
  #   end

  #   test "includes schedule for rail when appropriate", %{bus_shelter_screen: screen} do
  #     now = ~U[2020-01-01T00:00:00Z]

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: ~U[2020-01-01T02:20:00Z],
  #         departure_time: ~U[2020-01-01T02:20:00Z],
  #         route: %Route{type: :rail}
  #       },
  #       schedule: %Schedule{
  #         arrival_time: ~U[2020-01-01T02:15:00Z],
  #         departure_time: ~U[2020-01-01T02:15:00Z],
  #         route: %Route{type: :rail}
  #       }
  #     }

  #     assert [
  #              %{
  #                id: nil,
  #                crowding: nil,
  #                time: %{am_pm: :pm, hour: 9, minute: 20, type: :timestamp},
  #                scheduled_time: %{am_pm: :pm, hour: 9, minute: 15, type: :timestamp}
  #              }
  #            ] ==
  #              Departures.serialize_times_with_crowding([departure], screen, now)
  #   end

  #   test "doesn't include schedule when the same", %{bus_shelter_screen: screen} do
  #     now = ~U[2020-01-01T00:00:00Z]

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: ~U[2020-01-01T02:20:00Z],
  #         departure_time: ~U[2020-01-01T02:20:00Z],
  #         route: %Route{type: :rail}
  #       },
  #       schedule: %Schedule{
  #         arrival_time: ~U[2020-01-01T02:20:00Z],
  #         departure_time: ~U[2020-01-01T02:20:00Z],
  #         route: %Route{type: :rail}
  #       }
  #     }

  #     [result] = Departures.serialize_times_with_crowding([departure], screen, now)
  #     assert is_nil(Map.get(result, :scheduled_time))
  #   end

  #   test "doesn't include schedule when not rail", %{bus_shelter_screen: screen} do
  #     now = ~U[2020-01-01T00:00:00Z]

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: ~U[2020-01-01T02:20:00Z],
  #         departure_time: ~U[2020-01-01T02:20:00Z],
  #         route: %Route{type: :bus}
  #       },
  #       schedule: %Schedule{
  #         arrival_time: ~U[2020-01-01T02:15:00Z],
  #         departure_time: ~U[2020-01-01T02:15:00Z],
  #         route: %Route{type: :bus}
  #       }
  #     }

  #     [result] = Departures.serialize_times_with_crowding([departure], screen, now)
  #     assert is_nil(Map.get(result, :scheduled_time))
  #   end

  #   test "doesn't include schedule when prediction is ARR/BRD", %{bus_shelter_screen: screen} do
  #     now = ~U[2020-01-01T00:00:00Z]

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: ~U[2020-01-01T00:00:10Z],
  #         departure_time: ~U[2020-01-01T00:00:10Z],
  #         route: %Route{type: :rail}
  #       },
  #       schedule: %Schedule{
  #         arrival_time: ~U[2020-01-01T00:05:00Z],
  #         departure_time: ~U[2020-01-01T00:05:00Z],
  #         route: %Route{type: :rail}
  #       }
  #     }

  #     [result] = Departures.serialize_times_with_crowding([departure], screen, now)
  #     assert is_nil(Map.get(result, :scheduled_time))
  #     assert %{time: %{type: :text}} = result
  #   end

  #   test "doesn't include schedule when schedule is nil", %{bus_shelter_screen: screen} do
  #     now = ~U[2020-01-01T00:00:00Z]

  #     departure = %Departure{
  #       prediction: %Prediction{
  #         arrival_time: ~U[2020-01-01T02:20:00Z],
  #         departure_time: ~U[2020-01-01T02:20:00Z],
  #         route: %Route{type: :rail}
  #       }
  #     }

  #     [result] = Departures.serialize_times_with_crowding([departure], screen, now)
  #     assert is_nil(Map.get(result, :scheduled_time))
  #   end
  # end

  # describe "slot_names/1" do
  #   test "returns main_content" do
  #     instance = %Departures{section_data: []}
  #     assert [:main_content] == WidgetInstance.slot_names(instance)
  #   end
  # end

  # describe "widget_type/1" do
  #   test "returns departures" do
  #     instance = %Departures{section_data: []}
  #     assert :departures == WidgetInstance.widget_type(instance)
  #   end
  # end

  # describe "audio_serialize/1" do
  #   test "returns map with sections key" do
  #     instance = %Departures{}

  #     assert %{sections: _sections} = WidgetInstance.audio_serialize(instance)
  #   end
  # end

  # describe "audio_sort_key/1" do
  #   test "returns [1]" do
  #     instance = %Departures{}
  #     assert [1] == WidgetInstance.audio_sort_key(instance)
  #   end
  # end

  # describe "audio_valid_candidate?/1" do
  #   test "returns true" do
  #     instance = %Departures{}
  #     assert WidgetInstance.audio_valid_candidate?(instance)
  #   end
  # end

  # describe "audio_view/1" do
  #   test "returns DeparturesView" do
  #     instance = %Departures{}
  #     assert ScreensWeb.V2.Audio.DeparturesView == WidgetInstance.audio_view(instance)
  #   end
  # end
end
