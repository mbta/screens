defmodule Screens.V2.WidgetInstance.ElevatorStatusNewTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Elevator
  alias Screens.Elevator.Closure
  alias Screens.Facilities.Facility
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.ElevatorStatusNew, as: Widget
  alias Screens.V2.WidgetInstance.ElevatorStatusNew.Serialized
  alias ScreensConfig.FreeTextLine

  defp build_closure(facility_fields, elevator_fields \\ %{}) do
    %Closure{
      alert: %Alert{},
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

  describe "elevators without nearby redundancy are closed at this station" do
    test "one closure" do
      closures = [
        build_closure(
          [long_name: "Test Elevator 100", stop: %Stop{id: "place-here"}],
          redundancy: :in_station
        ),
        # has nearby redundancy; filter out
        build_closure([stop: %Stop{id: "place-here"}], redundancy: :nearby),
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
        qr_code_url: "https://mbta.com/stops/place-here"
      }

      assert Widget.serialize(%Widget{closures: closures, station_id: "place-here"}) == expected
    end

    test "one closure with summary" do
      closures = [
        build_closure(
          [long_name: "Test Elevator 100", stop: %Stop{id: "place-here"}],
          redundancy: :in_station,
          summary: "Use nearby elevator 101."
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
        qr_code_url: "https://mbta.com/stops/place-here"
      }

      assert Widget.serialize(%Widget{closures: closures, station_id: "place-here"}) == expected
    end

    test "multiple closures" do
      closures = [
        build_closure(long_name: "Test Elevator 100", stop: %Stop{id: "place-here"}),
        # no elevator data; not considered to have redundancy
        build_closure([long_name: "Test Elevator 101", stop: %Stop{id: "place-here"}], nil)
      ]

      expected = %Serialized{
        status: :alert,
        header: "Elevators are closed at this station.",
        callout_items: ["Test Elevator 100", "Test Elevator 101"],
        footer_lines:
          free_text_lines([
            ["Find an alternate path on ", %{format: :bold, text: "mbta.com/stops/place-here"}]
          ]),
        qr_code_url: "https://mbta.com/stops/place-here"
      }

      assert Widget.serialize(%Widget{closures: closures, station_id: "place-here"}) == expected
    end
  end

  describe "elevators without in-station redundancy are closed elsewhere" do
    test "one closure" do
      closures = [
        build_closure([stop: %Stop{id: "place-a", name: "Station A"}], redundancy: :backtrack),
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
        qr_code_url: "https://mbta.com/elevators"
      }

      assert Widget.serialize(%Widget{closures: closures, station_id: "place-here"}) == expected
    end

    test "multiple closures at one station" do
      closures = [
        build_closure([stop: %Stop{id: "place-a", name: "Station A"}], nil),
        build_closure([stop: %Stop{id: "place-a", name: "Station A"}], redundancy: :shuttle)
      ]

      expected = %Serialized{
        status: :alert,
        header: "Elevators closed at Station A",
        footer_lines:
          free_text_lines([["Check your trip at", %{format: :bold, text: "mbta.com/elevators"}]]),
        qr_code_url: "https://mbta.com/elevators"
      }

      assert Widget.serialize(%Widget{closures: closures, station_id: "place-here"}) == expected
    end

    test "closures at multiple stations" do
      closures = [
        # require alphabetical sorting in result
        build_closure([stop: %Stop{id: "place-b", name: "Station B"}], redundancy: :shuttle),
        build_closure([stop: %Stop{id: "place-a", name: "Station A"}], redundancy: :backtrack),
        build_closure([stop: %Stop{id: "place-a", name: "Station A"}], redundancy: :shuttle)
      ]

      expected = %Serialized{
        status: :alert,
        header: "Elevators closed at:",
        callout_items: ["Station A", "Station B"],
        footer_lines:
          free_text_lines([["Check your trip at", %{format: :bold, text: "mbta.com/elevators"}]]),
        qr_code_url: "https://mbta.com/elevators"
      }

      assert Widget.serialize(%Widget{closures: closures, station_id: "place-here"}) == expected
    end

    test "too many closures to list individually" do
      closures =
        Enum.map(~w[A B C D E F], fn id ->
          build_closure([stop: %Stop{id: "place-#{id}", name: "#{id}"}], redundancy: :backtrack)
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
        qr_code_url: "https://mbta.com/elevators"
      }

      assert Widget.serialize(%Widget{closures: closures, station_id: "place-here"}) == expected
    end

    test "specific long station names are abbreviated" do
      closures = [
        build_closure([stop: %Stop{id: "place-masta", name: "Massachusetts Avenue"}], nil)
      ]

      expected = %Serialized{
        status: :alert,
        header: "Elevator closed at Mass Ave",
        footer_lines:
          free_text_lines([["Check your trip at", %{format: :bold, text: "mbta.com/elevators"}]]),
        qr_code_url: "https://mbta.com/elevators"
      }

      assert Widget.serialize(%Widget{closures: closures, station_id: "place-here"}) == expected
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

      assert Widget.serialize(%Widget{closures: closures, station_id: "place-here"}) == expected
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

      assert Widget.serialize(%Widget{closures: closures, station_id: "place-here"}) == expected
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

      assert Widget.serialize(%Widget{closures: [], station_id: "place-here"}) == expected
    end
  end
end
