defmodule ScreensWeb.V2.Audio.DeparturesViewTest do
  use ScreensWeb.ConnCase, async: true

  alias ScreensWeb.V2.Audio.DeparturesView

  describe "intro" do
    @empty_section %{type: :normal_section, departure_groups: []}

    @non_empty_section %{
      type: :normal_section,
      header: nil,
      departure_groups: [
        normal: %{
          type: :departure_row,
          times_with_crowding: [
            %{
              id: "test1",
              time: %{type: :minutes, minutes: 1},
              crowding: nil
            }
          ],
          route: %{
            id: "Red",
            vehicle_type: :train,
            track_number: nil,
            route_text: "Red Line"
          },
          headsign: %{headsigns: ["Ashmont"], variation: nil}
        }
      ],
      wayfinding_readout: nil
    }

    test "announces no content when it is the first departures widget" do
      assigns = %{order: 0, sections: [@empty_section, @empty_section]}

      assert render(assigns) =~ "There are no upcoming trips at this time"
    end

    test "announces upcoming trips when it is the first departures widget" do
      assigns = %{order: 0, sections: [@non_empty_section]}

      assert render(assigns) =~ "Upcoming trips"
    end

    test "does not announce when it is not the first widget" do
      assert render(%{order: 1, sections: [@empty_section]}) == ""
      refute render(%{order: 1, sections: [@non_empty_section]}) =~ "Upcoming trips"
    end
  end

  describe "section with a header" do
    test "renders the header content" do
      assigns = %{
        order: 0,
        sections: [
          %{
            type: :normal_section,
            header: "Header",
            departure_groups: [
              {:notice, "Notice"}
            ],
            wayfinding_readout: nil
          }
        ]
      }

      assert render(assigns) =~ "Header"
    end
  end

  describe "overnight sections" do
    test "renders 'Service has ended' when routes is empty" do
      assigns = %{
        order: 0,
        sections: [
          %{
            type: :overnight_section,
            header: "Header",
            departure_groups: [],
            headsign: nil,
            routes: []
          }
        ]
      }

      assert render(assigns) =~ "Service has ended"
    end

    test "renders '<Route> service has ended' for a named route" do
      assigns = %{
        order: 0,
        sections: [
          %{
            type: :overnight_section,
            header: "Header",
            departure_groups: [],
            headsign: nil,
            routes: [%{long_name: "Blue Line"}]
          }
        ]
      }

      assert render(assigns) =~ "Blue Line service has ended"
    end

    test "renders wayfinding content" do
      wayfinding = "Use the crosswalk at College Ave to cross to the other side of the street."

      assigns = %{
        order: 0,
        sections: [
          %{
            type: :overnight_section,
            header: "Header",
            departure_groups: [
              {:notice, "Notice"}
            ],
            headsign: nil,
            routes: [],
            wayfinding_readout: wayfinding
          }
        ]
      }

      assert render(assigns) =~ wayfinding
    end
  end

  describe "no service sections" do
    test "renders 'No service today' when routes is empty" do
      assigns = %{
        order: 0,
        sections: [
          %{
            type: :no_service_section,
            header: "Header",
            departure_groups: [],
            headsign: nil,
            routes: []
          }
        ]
      }

      assert render(assigns) =~ "No service today"
    end

    test "renders '<Route> has no service today' for a named route" do
      assigns = %{
        order: 0,
        sections: [
          %{
            type: :no_service_section,
            header: "Header",
            departure_groups: [],
            headsign: nil,
            routes: [%{long_name: "Blue Line"}]
          }
        ]
      }

      assert render(assigns) =~ "Blue Line has no service today"
    end

    test "renders wayfinding content" do
      wayfinding = "Use the crosswalk at College Ave to cross to the other side of the street."

      assigns = %{
        order: 0,
        sections: [
          %{
            type: :no_service_section,
            header: "Header",
            departure_groups: [
              {:notice, "Notice"}
            ],
            headsign: nil,
            routes: [],
            wayfinding_readout: wayfinding
          }
        ]
      }

      assert render(assigns) =~ wayfinding
    end
  end

  describe "normal sections" do
    test "always read GL headsign" do
      assigns = %{
        order: 0,
        sections: [
          %{
            type: :normal_section,
            header: nil,
            departure_groups: [
              normal: %{
                type: :departure_row,
                times_with_crowding: [
                  %{
                    id: "test1",
                    time: %{type: :minutes, minutes: 1},
                    crowding: nil
                  },
                  %{
                    id: "test2",
                    time: %{type: :minutes, minutes: 6},
                    crowding: nil
                  }
                ],
                route: %{
                  id: "Green-B",
                  vehicle_type: :train,
                  track_number: nil,
                  route_text: "Green Line B"
                },
                headsign: %{headsigns: ["Boston College", "Boston Col"], variation: nil}
              },
              normal: %{
                type: :departure_row,
                times_with_crowding: [
                  %{
                    id: "test3",
                    time: %{type: :minutes, minutes: 1},
                    crowding: nil
                  },
                  %{
                    id: "test4",
                    time: %{type: :minutes, minutes: 6},
                    crowding: nil
                  }
                ],
                route: %{
                  id: "Red",
                  vehicle_type: :train,
                  track_number: nil,
                  route_text: "Red Line"
                },
                headsign: %{headsigns: ["Alewife"], variation: nil}
              }
            ],
            wayfinding_readout: nil
          }
        ]
      }

      assert render(assigns) =~
               "The next, Green Line B, train to, Boston College; arrives in, 1, minute"

      assert render(assigns) =~
               "The following, Green Line B, train to, Boston College; arrives in, 6, minutes"

      assert render(assigns) =~
               "The next, Red Line, train to, Alewife; arrives in, 1, minute"

      assert render(assigns) =~
               "The following, Red Line, train arrives in, 6, minutes"
    end

    test "reads track_number as 'at berth' for bus and 'on track' for CR" do
      assigns = %{
        order: 0,
        sections: [
          %{
            type: :normal_section,
            header: nil,
            departure_groups: [
              normal: %{
                type: :departure_row,
                times_with_crowding: [
                  %{
                    id: "test1",
                    time: %{type: :text, text: "BRD"},
                    crowding: 1
                  }
                ],
                route: %{id: "73", vehicle_type: :bus, track_number: "E", route_text: "73"},
                headsign: %{headsigns: ["Waverley"], variation: nil}
              },
              normal: %{
                type: :departure_row,
                times_with_crowding: [
                  %{
                    id: "test3",
                    time: %{type: :timestamp, minute: 31, hour: 12},
                    crowding: nil
                  }
                ],
                route: %{
                  id: "CR-Needham",
                  vehicle_type: :train,
                  track_number: "5",
                  route_text: "Needham Line"
                },
                headsign: %{headsigns: ["South Station"], variation: nil}
              }
            ],
            wayfinding_readout: nil
          }
        ]
      }

      assert render(assigns) =~
               "The next, <say-as interpret-as=\"address\">73</say-as>, bus to, Waverley; at berth, <say-as interpret-as=\"spell-out\">E</say-as>"

      assert render(assigns) =~
               "The next, Needham Line, train to, South Station; on track, 5, arrives at, 12:31"
    end

    test "renders wayfinding content" do
      wayfinding = "Use the crosswalk at College Ave to cross to the other side of the street."

      assigns = %{
        order: 0,
        sections: [
          %{
            type: :normal_section,
            header: "Header",
            departure_groups: [
              {:notice, "Notice"}
            ],
            wayfinding_readout: wayfinding
          }
        ]
      }

      assert render(assigns) =~ wayfinding
    end
  end

  ## helpers

  defp render(data) do
    "_widget.ssml"
    |> DeparturesView.render(data)
    |> Phoenix.HTML.safe_to_string()
    |> String.trim()
  end
end
