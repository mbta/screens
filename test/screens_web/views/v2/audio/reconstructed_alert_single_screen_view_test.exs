defmodule ScreensWeb.V2.Audio.ReconstructedAlertSingleScreenViewTest do
  use ExUnit.Case, async: true

  alias ScreensWeb.V2.Audio.ReconstructedAlertSingleScreenView

  defp render(alert) do
    "_widget.ssml"
    |> ReconstructedAlertSingleScreenView.render(alert)
    |> Phoenix.HTML.safe_to_string()
  end

  describe "render/2" do
    setup do
      base_alert = %{
        alternate_route_url: "mbta.com/alerts",
        qr_code_url: "go.mbta.com/a/450522/s/place-spmnl",
        cause: nil,
        effect: :suspension,
        issue: "No Green Line trains",
        location: "Green Line service is suspended between Government Center and Lechmere",
        region: :here,
        routes: [%{route_id: "Green", svg_name: "gl"}],
        updated_at: "Jul 13",
        end_time: nil,
        remedy: nil,
        endpoints: {"Government Center", "Lechmere"},
        is_transfer_station: true,
        show_alternate_route_text: true,
        unaffected_routes: [],
        stations: [
          "Lechmere",
          "Science Park",
          "North Station",
          "Haymarket",
          "Government Center"
        ],
        other_closures: []
      }

      %{base_alert: base_alert}
    end

    test "renders a downstream closure alert", %{base_alert: base_alert} do
      alert = %{
        base_alert
        | region: :outside,
          effect: :station_closure,
          routes: [
            %{route_id: "Green-D", svg_name: "gl", headsign: "Union Square"},
            %{route_id: "Green-E", svg_name: "gl", headsign: "Medford Tufts"}
          ]
      }

      assert render(alert) =~
               "Attention, riders to Union Square, and, Medford Tufts. Green Line branches, \
D, and, E, trains are skipping, Lechmere, Science Park, North Station, Haymarket, and, \
Government Center. Please seek an alternate route."
    end

    test "renders a downstream shuttle alert", %{base_alert: base_alert} do
      alert = %{
        base_alert
        | region: :outside,
          effect: :shuttle
      }

      assert render(alert) =~
               "Attention, Green line riders. Shuttle buses replace Green Line, trains between \
Government Center, and Lechmere. All shuttle buses are accessible."
    end

    test "renders a boundary shuttle alert", %{base_alert: base_alert} do
      alert = %{
        base_alert
        | region: :boundary,
          effect: :shuttle
      }

      assert render(alert) =~
               "Attention, Green line riders. There are No Green Line trains. Please use the \
shuttle bus. Shuttle buses are replacing, Green Line, trains between Government Center, and Lechmere. \
All shuttle buses are accessible."
    end

    test "renders a boundary suspension alert", %{base_alert: base_alert} do
      alert = %{
        base_alert
        | region: :boundary,
          effect: :suspension,
          cause: "maintenance"
      }

      assert render(alert) =~
               "There are No Green Line trains. Please seek an alternate route. Please note that \
there are no Green Line, trains between Government Center, and Lechmere, due to maintenance"
    end

    test "renders a single line, multiple station closure alert", %{base_alert: base_alert} do
      alert = %{
        base_alert
        | effect: :station_closure,
          cause: "maintenance",
          other_closures: ["Coolidge Corner"]
      }

      assert render(alert) =~
               "Attention, Green line riders. This station is closed due to maintenance. \
Please seek an alternate route. Green Line, trains are skipping this station and, Coolidge Corner."
    end

    test "renders a single line, transfer station closure alert", %{base_alert: base_alert} do
      alert = %{
        base_alert
        | effect: :station_closure,
          cause: "maintenance",
          unaffected_routes: [%{route_id: "Red", svg_name: "rl"}]
      }

      assert render(alert) =~
               "Green Line, trains are skipping this station due to maintenance. Please seek an \
alternate route. Red Line, trains are stopping here as usual."
    end

    test "renders a shuttle alert at a transfer station", %{base_alert: base_alert} do
      alert = %{
        base_alert
        | effect: :shuttle,
          cause: "maintenance"
      }

      assert render(alert) =~
               "There are no Green Line, trains. Please use the shuttle bus. Shuttle buses are replacing \
Green Line, trains between Government Center, and Lechmere, due to maintenance."
    end

    test "renders a shuttle alert at a non-transfer station", %{base_alert: base_alert} do
      alert =
        %{
          base_alert
          | effect: :shuttle,
            cause: "maintenance"
        }
        |> Map.delete(:is_transfer_station)

      assert render(alert) =~
               "This station is closed. Please use the shuttle bus. Shuttle buses are replacing \
Green Line, trains between Government Center, and Lechmere, due to maintenance."
    end

    test "renders a suspension at a transfer station", %{base_alert: base_alert} do
      alert = %{
        base_alert
        | effect: :suspension,
          cause: nil
      }

      assert render(alert) =~
               "There are no Green Line, trains. Please seek an alternate route. \
Please note that there are no Green Line, trains between Government Center, and Lechmere."
    end

    test "renders a suspension at a non-transfer station", %{base_alert: base_alert} do
      alert =
        %{
          base_alert
          | effect: :suspension,
            cause: nil
        }
        |> Map.delete(:is_transfer_station)

      assert render(alert) =~
               "This station is closed. Please seek an alternate route. \
Please note that there are no Green Line, trains between Government Center, and Lechmere."
    end
  end

  test "uses the full remedy in the single-screen fallback" do
    assigns = %{
      issue: "No service",
      remedy: [
        "Use shuttle buses to make connections to North Station",
        "Use shuttle buses to make connections to North Sta"
      ]
    }

    assert render(assigns) =~
             "No service. Use shuttle buses to make connections to North Station"
  end
end
