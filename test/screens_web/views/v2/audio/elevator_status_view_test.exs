defmodule ScreensWeb.V2.Audio.ElevatorStatusViewTest do
  use ScreensWeb.ConnCase, async: true
  alias ScreensWeb.V2.Audio.ElevatorStatusView

  describe "No elevator alerts" do
    test "renders all clear message" do
      assigns = %{
        active_at_home_pages: [],
        list_pages: [],
        upcoming_at_home_pages: [],
        elsewhere_pages: []
      }

      assert render(assigns) ==
               "\n    <p>Elevator Closures across the T.</p>\n    <p>All elevators are working at this station.</p>\n    <p>Other elevator closures:</p>\n    <p>All other MBTA elevators are working or have a backup elevator within 20 feet.</p>\n    "
    end
  end

  describe "Elevator alert" do
    test "with no additional closures renders closure message + other elevators working message" do
      assigns = %{
        active_at_home_pages: test_stations(),
        list_pages: [],
        upcoming_at_home_pages: [],
        elsewhere_pages: []
      }

      assert render(assigns) =~ "take a different elevator :)"

      assert render(assigns) =~
               "All other MBTA elevators are working or have a backup elevator within 20 feet."
    end

    test "with additional closures renders closure message + additional closures message" do
      assigns = %{
        active_at_home_pages: test_stations(),
        list_pages: test_stations(),
        upcoming_at_home_pages: [],
        elsewhere_pages: []
      }

      assert render(assigns) =~ "take a different elevator :)"
      assert render(assigns) =~ "For a full list of elevator alerts"
    end
  end

  ## Helper functions

  defp test_stations do
    [
      %{
        station: %{
          is_at_home_stop: true,
          name: "Haymarket",
          elevator_closures: [
            %{
              elevator_id: "1",
              elevator_name: "Haymarket",
              description: "take a different elevator :)",
              timeframe: %{
                active_period: %{
                  "start" => "2022-01-01T00:00:00Z",
                  "end" => "2022-01-01T22:00:00Z"
                },
                happening_now: true
              }
            }
          ]
        }
      }
    ]
  end

  defp render(data) do
    "_widget.ssml"
    |> ElevatorStatusView.render(data)
    |> Phoenix.HTML.safe_to_string()
  end
end
