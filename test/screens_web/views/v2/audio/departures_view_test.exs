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
          headsign: %{headsign: "Ashmont", variation: nil}
        }
      ]
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
            ]
          }
        ]
      }

      assert render(assigns) =~ "Header"
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
                headsign: %{headsign: "Boston College", variation: nil}
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
                headsign: %{headsign: "Alewife", variation: nil}
              }
            ]
          }
        ]
      }

      assert render(assigns) =~
               "The next Green Line B train to Boston College arrives in 1 minute"

      assert render(assigns) =~
               "The following Green Line B train to Boston College arrives in 6 minutes"

      assert render(assigns) =~
               "The next Red Line train to Alewife arrives in 1 minute"

      assert render(assigns) =~
               "The following Red Line train arrives in 6 minutes"
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
                headsign: %{headsign: "Waverley", variation: nil}
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
                headsign: %{headsign: "South Station", variation: nil}
              }
            ]
          }
        ]
      }

      assert render(assigns) =~
               "The next <say-as interpret-as=\"address\">73</say-as> bus to Waverley at berth <break strength=\"weak\"/><say-as interpret-as=\"spell-out\">E</say-as>"

      assert render(assigns) =~
               "The next Needham Line train to South Station on track 5"
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
