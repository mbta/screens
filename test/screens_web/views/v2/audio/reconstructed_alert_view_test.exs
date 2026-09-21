defmodule ScreensWeb.V2.Audio.ReconstructedAlertViewTest do
  use ExUnit.Case, async: true

  alias ScreensWeb.V2.Audio.ReconstructedAlertView

  defp render(assigns) do
    "_widget.ssml"
    |> ReconstructedAlertView.render(assigns)
    |> Phoenix.HTML.safe_to_string()
  end

  test "uses the full issue for a downstream station closure" do
    assigns = %{
      issue: [
        "This is a test alert affecting both North Station and Tufts Medical Center for some reason",
        "This is a test alert affecting both North Sta and Tufts Med for some reason"
      ],
      remedy: "",
      cause: "due to maintenance",
      region: :outside,
      effect: :station_closure
    }

    assert render(assigns) ==
             "<p>This is a test alert affecting both North Station and Tufts Medical Center for some reason due to maintenance.</p>"
  end

  test "uses the full issue for a delay" do
    assigns = %{
      issue: [
        "Delays of about 20 minutes affecting North Station",
        "Delays of about 20 minutes affecting North Sta"
      ],
      routes: [%{color: "Orange"}],
      urgent: false,
      effect: :delay
    }

    assert render(assigns) ==
             "<p>Orange Line delay. Delays of about 20 minutes affecting North Station.</p>"
  end

  test "uses the full issue for other alerts" do
    assigns = %{
      issue: ["No trains at Government Center", "No trains at Gov't Ctr"],
      remedy: "Seek alternate route",
      cause: "due to maintenance",
      location: "",
      routes: [%{color: "Red"}],
      effect: :suspension
    }

    assert render(assigns) ==
             "<p>Red Line alert. No trains at Government Center due to maintenance. Please seek an alternate route.</p>"
  end
end
