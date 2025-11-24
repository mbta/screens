defmodule Screens.V2.WidgetInstance.ElevatorStatusTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Elevator
  alias Screens.Elevator.Closure
  alias Screens.Facilities.Facility
  alias Screens.Stops.Stop
  alias Screens.V2.AlertsWidget
  alias Screens.V2.WidgetInstance.ElevatorStatus, as: Widget
  alias Screens.V2.WidgetInstance.ElevatorStatus.Serialized
  alias ScreensConfig.FreeTextLine

  defp build_closure(facility_fields, elevator_fields \\ %{}, alert_id \\ "0") do
    %Closure{
      alert: %Alert{id: alert_id},
      elevator: if(is_nil(elevator_fields), do: nil, else: build_elevator(elevator_fields)),
      facility: build_facility(facility_fields)
    }
  end

  defp build_elevator(fields) do
    struct!(
      %Elevator{
        id: "111",
        alternate_ids: [],
        exiting_summary: "",
        redundancy: :in_station,
        summary: nil
      },
      fields
    )
  end

  defp build_facility(fields) do
    struct!(
      %Facility{
        id: "111",
        long_name: "long",
        short_name: "short",
        type: :elevator,
        stop: %Stop{id: "place-test"}
      },
      fields
    )
  end

  defp free_text_lines(lines), do: Enum.map(lines, &%FreeTextLine{icon: nil, text: &1})

  describe "AlertsWidget implementation" do
    test "returns the value of Serialized.alert_ids" do
      # This way we know the AlertsWidget implementation is actually hooked up to the `alert_ids`
      # field of `Serialized`, and tests that assert on this field are meaningful
      closures = [build_closure([stop: %Stop{id: "place-here"}], [redundancy: :in_station], "a1")]
      widget = %Widget{closures: closures, home_station_id: "place-here"}

      assert AlertsWidget.alert_ids(widget) == Widget.serialize(widget).alert_ids
    end
  end

  describe "elevators without nearby redundancy are closed at this station" do
    test "one closure" do
      closures = [
        build_closure(
          [long_name: "Test Elevator 100", stop: %Stop{id: "place-here"}],
          [redundancy: :in_station],
          "alert-1"
        ),
        # not at this station; irrelevant
        build_closure(stop: %Stop{id: "place-other"})
      ]

      expected = %Serialized{
        status: :alert,
        header: "An elevator is closed at this station.",
        footer_lines:
          free_text_lines([
            ["Test Elevator 100 is unavailable."],
            ["Find an alternate path on ", %{format: :bold, text: "mbta.com/stops/place-here"}]
          ]),
        qr_code_url: "https://go.mbta.com/a/alert-1/s/place-here",
        alert_ids: ["alert-1"]
      }

      assert Widget.serialize(%Widget{closures: closures, home_station_id: "place-here"}) ==
               expected
    end

    test "one closure with summary" do
      closures = [
        build_closure(
          [long_name: "Test Elevator 100", stop: %Stop{id: "place-here"}],
          [redundancy: :in_station, summary: "Use nearby elevator 101."],
          "alert-1"
        )
      ]

      expected = %Serialized{
        status: :alert,
        header: "An elevator is closed at this station.",
        footer_lines:
          free_text_lines([
            ["Test Elevator 100 is unavailable.", "Use nearby elevator 101."],
            ["For more info, go to ", %{format: :bold, text: "mbta.com/stops/place-here"}]
          ]),
        qr_code_url: "https://go.mbta.com/a/alert-1/s/place-here",
        alert_ids: ["alert-1"]
      }

      assert Widget.serialize(%Widget{closures: closures, home_station_id: "place-here"}) ==
               expected
    end

    test "multiple closures" do
      # ensure lexical ordering of elevator names
      closures = [
        build_closure([long_name: "Test Elevator B", stop: %Stop{id: "place-here"}], %{}, "a1"),
        # no elevator data; not considered to have redundancy
        build_closure([long_name: "Test Elevator A", stop: %Stop{id: "place-here"}], nil, "a2")
      ]

      expected = %Serialized{
        status: :alert,
        header: "Elevators are closed at this station.",
        callout_items: ["Test Elevator A", "Test Elevator B"],
        footer_lines:
          free_text_lines([
            ["Find an alternate path on ", %{format: :bold, text: "mbta.com/stops/place-here"}]
          ]),
        qr_code_url: "https://go.mbta.com/s/place-here",
        alert_ids: ~w[a1 a2]
      }

      assert Widget.serialize(%Widget{closures: closures, home_station_id: "place-here"}) ==
               expected
    end

    test "includes closures with nearby redundancy at the same station" do
      closures = [
        # triggers the closures-here state
        build_closure(
          [long_name: "Test 1", stop: %Stop{id: "place-here"}],
          [redundancy: :in_station],
          "a1"
        ),
        # would not trigger the state on its own, but included because we're already in it
        build_closure(
          [long_name: "Test 2", stop: %Stop{id: "place-here"}],
          [redundancy: :nearby],
          "a2"
        )
      ]

      expected = %Serialized{
        status: :alert,
        header: "Elevators are closed at this station.",
        callout_items: ["Test 1", "Test 2"],
        footer_lines:
          free_text_lines([
            ["Find an alternate path on ", %{format: :bold, text: "mbta.com/stops/place-here"}]
          ]),
        qr_code_url: "https://go.mbta.com/s/place-here",
        alert_ids: ~w[a1 a2]
      }

      assert Widget.serialize(%Widget{closures: closures, home_station_id: "place-here"}) ==
               expected
    end

    test "always includes elevators whose alternates are also closed" do
      closures = [
        build_closure(
          [long_name: "Test Elevator 100", stop: %Stop{id: "place-here"}],
          [alternate_ids: ["alt"], redundancy: :nearby],
          "alert-1"
        ),
        build_closure(id: "alt")
      ]

      expected = %Serialized{
        status: :alert,
        header: "An elevator is closed at this station.",
        footer_lines:
          free_text_lines([
            ["Test Elevator 100 is unavailable."],
            ["Find an alternate path on ", %{format: :bold, text: "mbta.com/stops/place-here"}]
          ]),
        qr_code_url: "https://go.mbta.com/a/alert-1/s/place-here",
        alert_ids: ["alert-1"]
      }

      assert Widget.serialize(%Widget{closures: closures, home_station_id: "place-here"}) ==
               expected
    end
  end

  describe "elevators without in-station redundancy are closed elsewhere" do
    test "one closure" do
      closures = [
        build_closure(
          [stop: %Stop{id: "place-a", name: "Station A"}],
          [redundancy: :backtrack],
          "alert-a"
        ),
        # have in-station or nearby redundancy; include in summary
        build_closure([stop: %Stop{id: "place-b"}], redundancy: :in_station),
        build_closure([stop: %Stop{id: "place-c"}], redundancy: :nearby)
      ]

      expected = %Serialized{
        status: :alert,
        header: "Elevator closed at Station A",
        footer_lines:
          free_text_lines([
            [
              %{format: :bold, text: "+2 other MBTA elevators are closed"},
              "(which have in-station alternative paths).",
              "Check your trip at",
              %{format: :bold, text: "mbta.com/elevators"}
            ]
          ]),
        qr_code_url: "https://mbta.com/elevators",
        alert_ids: ["alert-a"]
      }

      assert Widget.serialize(%Widget{closures: closures, home_station_id: "place-here"}) ==
               expected
    end

    test "multiple closures at one station" do
      closures = [
        build_closure([stop: %Stop{id: "place-a", name: "ABC"}], [redundancy: :shuttle], "a1"),
        # has in-station redundancy, but another closed elevator at the same station doesn't,
        # so "Elevators closed at ABC" already includes it and it should not be double-included
        # in the footer summary
        build_closure([stop: %Stop{id: "place-a", name: "ABC"}], [redundancy: :nearby], "a2")
      ]

      expected = %Serialized{
        status: :alert,
        header: "Elevators closed at ABC",
        footer_lines:
          free_text_lines([["Check your trip at", %{format: :bold, text: "mbta.com/elevators"}]]),
        qr_code_url: "https://mbta.com/elevators",
        alert_ids: ~w[a1 a2]
      }

      assert Widget.serialize(%Widget{closures: closures, home_station_id: "place-here"}) ==
               expected
    end

    test "closures at multiple stations" do
      closures = [
        build_closure([stop: %Stop{id: "place-a", name: "A"}], [redundancy: :backtrack], "a1"),
        build_closure([stop: %Stop{id: "place-a", name: "A"}], [redundancy: :shuttle], "a2"),
        build_closure([stop: %Stop{id: "place-b", name: "B"}], [redundancy: :shuttle], "a3")
      ]

      expected = %Serialized{
        status: :alert,
        header: "Elevators closed at:",
        callout_items: ["A", "B"],
        footer_lines:
          free_text_lines([["Check your trip at", %{format: :bold, text: "mbta.com/elevators"}]]),
        qr_code_url: "https://mbta.com/elevators",
        alert_ids: ~w[a1 a2 a3]
      }

      assert Widget.serialize(%Widget{closures: closures, home_station_id: "place-here"}) ==
               expected
    end

    test "too many closures to list individually" do
      closures =
        ~w[A B C D E F]
        |> Enum.with_index()
        |> Enum.map(fn {id, index} ->
          build_closure(
            [stop: %Stop{id: "place-#{id}", name: "#{id}"}],
            [redundancy: :backtrack],
            "a#{index}"
          )
        end)

      expected = %Serialized{
        status: :alert,
        header: "Elevators closed at:",
        callout_items: ~w[A B C D],
        footer_lines:
          free_text_lines([
            [
              "+2 other MBTA elevators are closed,",
              %{format: :bold, text: "which have no in-station alternative paths."},
              "Check your trip at",
              %{format: :bold, text: "mbta.com/elevators"}
            ]
          ]),
        qr_code_url: "https://mbta.com/elevators",
        alert_ids: ~w[a0 a1 a2 a3 a4 a5]
      }

      assert Widget.serialize(%Widget{closures: closures, home_station_id: "place-here"}) ==
               expected
    end

    test "always includes elevators whose alternates are also closed" do
      closures = [
        build_closure(
          [stop: %Stop{id: "place-a", name: "Station A"}],
          [alternate_ids: ["alt"], redundancy: :in_station],
          "alert-a"
        ),
        build_closure([id: "alt"], redundancy: :in_station)
      ]

      expected = %Serialized{
        status: :alert,
        header: "Elevator closed at Station A",
        footer_lines:
          free_text_lines([
            [
              %{format: :bold, text: "+1 other MBTA elevator is closed"},
              "(which has an in-station alternative path).",
              "Check your trip at",
              %{format: :bold, text: "mbta.com/elevators"}
            ]
          ]),
        qr_code_url: "https://mbta.com/elevators",
        alert_ids: ["alert-a"]
      }

      assert Widget.serialize(%Widget{closures: closures, home_station_id: "place-here"}) ==
               expected
    end

    test "abbreviates specific long station names" do
      closures = [
        build_closure([stop: %Stop{id: "place-masta", name: "Massachusetts Avenue"}], nil, "a1")
      ]

      expected = %Serialized{
        status: :alert,
        header: "Elevator closed at Mass Ave",
        footer_lines:
          free_text_lines([["Check your trip at", %{format: :bold, text: "mbta.com/elevators"}]]),
        qr_code_url: "https://mbta.com/elevators",
        alert_ids: ["a1"]
      }

      assert Widget.serialize(%Widget{closures: closures, home_station_id: "place-here"}) ==
               expected
    end

    test "sorts multiple stations first by relevance and then by name" do
      closures = [
        build_closure([stop: %Stop{id: "place-b", name: "Beta"}], nil, "a1"),
        build_closure([stop: %Stop{id: "place-a", name: "Alpha"}], nil, "a2"),
        build_closure([stop: %Stop{id: "place-rel", name: "Relevant"}], nil, "a3")
      ]

      expected = %Serialized{
        status: :alert,
        header: "Elevators closed at:",
        callout_items: ["Relevant", "Alpha", "Beta"],
        footer_lines:
          free_text_lines([["Check your trip at", %{format: :bold, text: "mbta.com/elevators"}]]),
        qr_code_url: "https://mbta.com/elevators",
        alert_ids: ~w[a2 a1 a3]
      }

      assert Widget.serialize(%Widget{
               closures: closures,
               home_station_id: "place-here",
               relevant_station_ids: ~w[place-rel]
             }) == expected
    end
  end

  describe "elevators with in-station redundancy are closed elsewhere" do
    test "multiple closures" do
      closures = [
        build_closure([stop: %Stop{id: "place-a"}], redundancy: :in_station),
        build_closure([stop: %Stop{id: "place-b"}], redundancy: :nearby)
      ]

      expected = %Serialized{
        status: :ok,
        header: "All elevators at this station are working.",
        footer_lines:
          free_text_lines([
            [
              %{format: :bold, text: "+2 other MBTA elevators are closed"},
              "(which have in-station alternative paths).",
              "Check your trip at",
              %{format: :bold, text: "mbta.com/elevators"}
            ]
          ]),
        qr_code_url: "https://mbta.com/elevators"
      }

      assert Widget.serialize(%Widget{closures: closures, home_station_id: "place-here"}) ==
               expected
    end
  end

  describe "all elevators are working or have nearby redundancy" do
    test "with closures" do
      closures = [build_closure([], redundancy: :nearby), build_closure([], redundancy: :nearby)]

      expected = %Serialized{
        status: :ok,
        header: "All MBTA elevators are working",
        header_size: :large,
        footer_lines: free_text_lines([["or have a backup within 20 feet."]]),
        cta_type: :app,
        qr_code_url: "https://mbta.com/go-access"
      }

      assert Widget.serialize(%Widget{closures: closures, home_station_id: "place-here"}) ==
               expected
    end

    test "without closures" do
      expected = %Serialized{
        status: :ok,
        header: "All MBTA elevators are working.",
        header_size: :large,
        footer_lines: [],
        cta_type: :app,
        qr_code_url: "https://mbta.com/go-access"
      }

      assert Widget.serialize(%Widget{closures: [], home_station_id: "place-here"}) == expected
    end
  end
end
